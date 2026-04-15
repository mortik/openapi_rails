# frozen_string_literal: true

module OpenapiRails
  class SchemasController < ActionController::API
    def show
      schema_name = params[:id]
      config = OpenapiRails.configuration

      schema_config = config.schemas[schema_name.to_sym]
      return head :not_found unless schema_config

      file_path = schema_file_path(schema_name)
      return head :not_found unless file_path && File.exist?(file_path)

      content = File.read(file_path)

      # Apply filter if configured
      if schema_config[:openapi_filter]
        doc = parse_content(file_path, content)
        schema_config[:openapi_filter].call(doc, request)
        content = serialize_doc(file_path, doc)
      end

      content_type = file_path.end_with?(".json") ? "application/json" : "application/x-yaml"
      render plain: content, content_type: content_type
    end

    def index
      schemas = OpenapiRails.configuration.schemas.keys.map(&:to_s)
      render json: {schemas: schemas}
    end

    private

    def schema_file_path(schema_name)
      config = OpenapiRails.configuration
      ext = (config.schema_output_format == :json) ? "json" : "yaml"
      path = Rails.root.join(config.schema_output_dir, "#{schema_name}.#{ext}")
      path.to_s
    end

    def parse_content(file_path, content)
      if file_path.end_with?(".json")
        JSON.parse(content)
      else
        YAML.safe_load(content, permitted_classes: [Date, Time])
      end
    end

    def serialize_doc(file_path, doc)
      if file_path.end_with?(".json")
        JSON.pretty_generate(doc)
      else
        doc.to_yaml
      end
    end
  end
end
