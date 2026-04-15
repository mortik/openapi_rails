# frozen_string_literal: true

module OpenapiRails
  class Engine < ::Rails::Engine
    isolate_namespace OpenapiRails

    initializer "openapi_rails.middleware" do |app|
      config = OpenapiRails.configuration

      if config.request_validation != :disabled || config.response_validation != :disabled
        spec_path = default_spec_path(config)

        if spec_path && File.exist?(spec_path)
          resolver = Middleware::SchemaResolver.new(spec_path: spec_path)

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
        Dir[expanded.join("**", "*.rb")].sort.each { |f| require f } if expanded.exist?
      end
    end

    private

    def default_spec_path(config)
      return nil if config.specs.empty?

      spec_name = config.specs.keys.first
      ext = (config.spec_output_format == :json) ? "json" : "yaml"
      Rails.root.join(config.spec_output_dir, "#{spec_name}.#{ext}").to_s
    end
  end
end
