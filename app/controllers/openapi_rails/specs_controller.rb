# frozen_string_literal: true

module OpenapiRails
  class SpecsController < ActionController::API
    def show
      spec_name = params[:id]
      config = OpenapiRails.configuration

      spec_config = config.specs[spec_name.to_sym]
      return head :not_found unless spec_config

      file_path = spec_file_path(spec_name)
      return head :not_found unless file_path && File.exist?(file_path)

      content = File.read(file_path)

      # Apply filter if configured
      if spec_config[:openapi_filter]
        doc = parse_content(file_path, content)
        spec_config[:openapi_filter].call(doc, request)
        content = serialize_doc(file_path, doc)
      end

      content_type = file_path.end_with?(".json") ? "application/json" : "application/x-yaml"
      render plain: content, content_type: content_type
    end

    def index
      specs = OpenapiRails.configuration.specs.keys.map(&:to_s)
      render json: {specs: specs}
    end

    private

    def spec_file_path(spec_name)
      config = OpenapiRails.configuration
      ext = (config.spec_output_format == :json) ? "json" : "yaml"
      path = Rails.root.join(config.spec_output_dir, "#{spec_name}.#{ext}")
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
