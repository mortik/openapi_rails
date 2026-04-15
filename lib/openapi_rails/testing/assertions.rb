# frozen_string_literal: true

module OpenapiRails
  module Testing
    module Assertions
      def assert_response_schema_conform(expected_status = nil, spec_path: nil)
        doc = load_openapi_document(spec_path)
        validator = ResponseValidator.new(doc)

        status = expected_status || response.status
        path_template = find_matching_path(request.path, doc)
        method = request.request_method.downcase

        body = parse_json_response

        errors = validator.validate_against_document(
          response_body: body,
          status_code: status,
          path: path_template,
          method: method
        )

        assert_message = "Response schema validation failed:\n#{errors.join("\n")}"

        if defined?(RSpec)
          expect(errors).to be_empty, assert_message
        else
          assert errors.empty?, assert_message
        end
      end

      def assert_request_schema_conform(spec_path: nil)
        doc = load_openapi_document(spec_path)
        path_template = find_matching_path(request.path, doc)
        method = request.request_method.downcase

        operation = doc.dig("paths", path_template, method)
        assert_or_expect(operation, "Operation not found: #{method.upcase} #{path_template}")

        errors = validate_request_params(operation)
        assert_message = "Request schema validation failed:\n#{errors.join("\n")}"

        if defined?(RSpec)
          expect(errors).to be_empty, assert_message
        else
          assert errors.empty?, assert_message
        end
      end

      private

      def load_openapi_document(spec_path = nil)
        path = spec_path || default_schema_path
        raise OpenapiRails::Error, "No OpenAPI schema path configured" unless path

        @_openapi_documents ||= {}
        @_openapi_documents[path] ||= begin
          raw = File.read(path)
          if path.end_with?(".yaml", ".yml")
            YAML.safe_load(raw, permitted_classes: [Date, Time])
          else
            JSON.parse(raw)
          end
        end
      end

      def default_schema_path
        config = OpenapiRails.configuration
        return nil if config.schemas.empty?

        schema_name = config.schemas.keys.first
        ext = (config.schema_output_format == :json) ? "json" : "yaml"
        File.join(config.schema_output_dir, "#{schema_name}.#{ext}")
      end

      def find_matching_path(request_path, document)
        matcher = Middleware::PathMatcher.new(document.fetch("paths", {}).keys)
        result = matcher.match(request_path)
        result&.first || request_path
      end

      def parse_json_response
        return nil if response.body.empty?

        JSON.parse(response.body)
      rescue JSON::ParserError
        response.body
      end

      def validate_request_params(operation)
        errors = []
        parameters = operation.fetch("parameters", [])

        parameters.each do |param|
          next unless param["required"]

          value = case param["in"]
          when "query" then request.GET[param["name"]]
          when "header" then request.get_header("HTTP_#{param["name"].upcase.tr("-", "_")}")
          when "path" then nil # Already resolved via routing
          end

          errors << "Missing required #{param["in"]} parameter: #{param["name"]}" if value.nil? && param["in"] != "path"
        end

        errors
      end

      def assert_or_expect(value, message)
        if defined?(RSpec)
          expect(value).to be_truthy, message
        else
          assert value, message
        end
      end
    end
  end
end
