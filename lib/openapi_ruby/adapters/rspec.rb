# frozen_string_literal: true

require "openapi_ruby"
require "uri"

module OpenapiRuby
  module Adapters
    module RSpec
      # Class-level DSL methods extended onto :openapi example groups.
      # All methods are inherited by nested describe/context/it_behaves_like blocks.
      # Data is stored in RSpec metadata which propagates to child groups.
      module ExampleGroupHelpers
        def path(template, &block)
          schema_name = metadata[:openapi_schema_name]
          context = DSL::Context.new(template, schema_name: schema_name)

          describe template do
            metadata[:openapi_path_context] = context
            instance_eval(&block) if block
            DSL::MetadataStore.register(context)
          end
        end

        DSL::Context::HTTP_METHODS.each do |method|
          define_method(method) do |summary = nil, &block|
            path_ctx = metadata[:openapi_path_context]
            op_context = DSL::OperationContext.new(method, summary)
            path_ctx.path_parameters.each { |p| op_context.parameter(p) }
            path_ctx.operations[method.to_s] = op_context

            describe "#{method.to_s.upcase} #{path_ctx.path_template}" do
              metadata[:openapi_operation] = op_context
              instance_eval(&block) if block
            end
          end
        end

        def parameter(attributes = {})
          if metadata[:openapi_operation]
            metadata[:openapi_operation].parameter(attributes)
          elsif metadata[:openapi_path_context]
            metadata[:openapi_path_context].parameter(attributes)
          end
        end

        %i[tags operationId deprecated security].each do |attr_name|
          define_method(attr_name) do |value|
            metadata[:openapi_operation]&.send(attr_name, value)
          end
        end

        def description(value = nil)
          return super() if value.nil?
          metadata[:openapi_operation]&.description(value)
        end

        def consumes(*content_types)
          metadata[:openapi_operation]&.consumes(*content_types)
        end

        def produces(*content_types)
          metadata[:openapi_operation]&.produces(*content_types)
        end

        def request_body(attributes = {})
          metadata[:openapi_operation]&.request_body(attributes)
        end

        def request_body_example(**kwargs)
          metadata[:openapi_operation]&.request_body_example(**kwargs)
        end

        def response(status_code, description, hidden: false, &block)
          operation = metadata[:openapi_operation]
          response_ctx = operation.response(status_code, description, hidden: hidden)

          context "response #{status_code} #{description}" do
            metadata[:openapi_response] = response_ctx
            instance_eval(&block) if block
          end
        end

        def schema(definition)
          metadata[:openapi_response]&.schema(definition)
        end

        def header(name, attributes = {})
          metadata[:openapi_response]&.header(name, attributes)
        end

        def run_test!(description = nil, &block)
          response_ctx = metadata[:openapi_response]

          before do |example|
            submit_openapi_request(example.metadata)
          end

          it(description || "returns #{response_ctx.status_code}") do |example|
            assert_openapi_response(example.metadata)
            instance_eval(&block) if block
          end
        end
      end

      # Instance-level helper methods mixed into RSpec examples
      module ExampleHelpers
        private

        def submit_openapi_request(metadata)
          path = resolve_path(metadata)
          operation = find_in_metadata(metadata, :openapi_operation)

          params = resolve_let(:request_params) || {}
          headers = resolve_let(:request_headers) || {}
          body = resolve_let(:request_body)

          # Merge individual parameter let values
          operation&.parameters&.each do |param|
            name = param["name"]
            val = resolve_let(name.to_sym)
            next unless val

            case param["in"]
            when "query" then params[name] = val
            when "header" then headers[name] = val
            end
          end

          method = operation&.verb || "get"
          # Default to JSON Accept header for API requests
          headers["Accept"] ||= "application/json"
          request_args = {params: params, headers: headers}

          if body
            content_type = operation&.request_body_definition&.dig("content")&.keys&.first || "application/json"
            if content_type.include?("form-data") || content_type.include?("x-www-form-urlencoded")
              request_args[:params] = body
            else
              request_args[:params] = body.is_a?(String) ? body : body.to_json
              request_args[:headers] = headers.merge("Content-Type" => content_type)
            end
          end

          send(method.to_sym, path, **request_args)
        end

        def assert_openapi_response(metadata)
          response_ctx = find_in_metadata(metadata, :openapi_response)

          expected_status = response_ctx.status_code.to_i
          actual_status = response.status

          unless actual_status == expected_status
            raise "Response validation failed:\n" \
              "Expected status #{expected_status}, got #{actual_status}\n" \
              "Response body: #{response.body}"
          end
        end

        def resolve_path(metadata)
          path_ctx = find_in_metadata(metadata, :openapi_path_context)
          template = path_ctx&.path_template || ""

          base_path = resolve_base_path(path_ctx&.schema_name)
          full_path = "#{base_path}#{template}"

          full_path.gsub(/\{(\w+)\}/) do
            name = ::Regexp.last_match(1)
            resolve_let(name.to_sym) || "{#{name}}"
          end
        end

        def find_in_metadata(metadata, key)
          meta = metadata
          while meta
            return meta[key] if meta[key]
            meta = meta[:parent_example_group]
          end
          nil
        end

        def resolve_base_path(schema_name)
          return "" unless schema_name

          config = OpenapiRuby.configuration
          schema_config = config.schemas[schema_name.to_sym] || config.schemas[schema_name.to_s]
          return "" unless schema_config

          server_url = schema_config.dig(:servers, 0, :url) || schema_config.dig("servers", 0, "url")
          return "" unless server_url

          URI.parse(server_url).path.chomp("/")
        rescue URI::InvalidURIError
          ""
        end

        def resolve_let(name)
          send(name)
        rescue NameError
          nil
        end

        def parsed_response_body
          return nil if response.body.empty?
          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end
      end

      def self.install!
        ::RSpec.configure do |config|
          config.extend ExampleGroupHelpers, type: :openapi
          config.include ExampleHelpers, type: :openapi

          if defined?(::RSpec::Rails)
            config.include ::RSpec::Rails::RequestExampleGroup, type: :openapi
          end

          config.after(:suite) do
            OpenapiRuby::Generator::SchemaWriter.generate_all!
          rescue => e
            warn "[openapi_ruby] Schema generation failed: #{e.message}"
          end
        end
      end
    end
  end
end
