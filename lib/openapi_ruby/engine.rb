# frozen_string_literal: true

module OpenapiRuby
  class Engine < ::Rails::Engine
    isolate_namespace OpenapiRuby

    initializer "openapi_ruby.middleware" do |app|
      config = OpenapiRuby.configuration

      next if ENV["OPENAPI_RUBY_GENERATING"]

      if config.request_validation != :disabled || config.response_validation != :disabled
        config.schemas.each do |name, schema_config|
          schema_path = resolve_schema_path(config, name)
          next unless schema_path && File.exist?(schema_path)

          resolver = Middleware::SchemaResolver.new(
            spec_path: schema_path,
            strict_reference_validation: config.strict_reference_validation
          )

          prefix = schema_config[:prefix]

          if config.request_validation != :disabled
            app.middleware.use Middleware::RequestValidation,
              schema_resolver: resolver,
              mode: config.request_validation,
              prefix: prefix
          end

          if config.response_validation != :disabled
            app.middleware.use Middleware::ResponseValidation,
              schema_resolver: resolver,
              mode: config.response_validation,
              prefix: prefix
          end
        end
      end
    end

    private

    def resolve_schema_path(config, schema_name)
      ext = (config.schema_output_format == :json) ? "json" : "yaml"
      Rails.root.join(config.schema_output_dir, "#{schema_name}.#{ext}").to_s
    end
  end
end
