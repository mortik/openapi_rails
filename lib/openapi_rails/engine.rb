# frozen_string_literal: true

module OpenapiRails
  class Engine < ::Rails::Engine
    isolate_namespace OpenapiRails

    initializer "openapi_rails.middleware" do |app|
      config = OpenapiRails.configuration

      if config.request_validation != :disabled || config.response_validation != :disabled
        schema_path = default_schema_path(config)

        if schema_path && File.exist?(schema_path)
          resolver = Middleware::SchemaResolver.new(spec_path: schema_path)

          if config.request_validation != :disabled
            app.middleware.use Middleware::RequestValidation,
              schema_resolver: resolver,
              mode: config.request_validation
          end

          if config.response_validation != :disabled
            app.middleware.use Middleware::ResponseValidation,
              schema_resolver: resolver,
              mode: config.response_validation
          end
        end
      end
    end

    initializer "openapi_rails.components" do
      config = OpenapiRails.configuration
      config.component_paths.each do |path|
        expanded = Rails.root.join(path)
        next unless expanded.exist?

        # Auto-define modules for subdirectories (Schemas, Parameters, etc.)
        expanded.children.select(&:directory?).each do |dir|
          mod_name = dir.basename.to_s.camelize.to_sym
          Object.const_set(mod_name, Module.new) unless Object.const_defined?(mod_name)
        end

        Dir[expanded.join("**", "*.rb")].sort.each { |f| require f }
      end
    end

    private

    def default_schema_path(config)
      return nil if config.schemas.empty?

      schema_name = config.schemas.keys.first
      ext = (config.schema_output_format == :json) ? "json" : "yaml"
      Rails.root.join(config.schema_output_dir, "#{schema_name}.#{ext}").to_s
    end
  end
end
