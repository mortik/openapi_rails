# frozen_string_literal: true

module OpenapiRails
  class UiController < ActionController::Base
    layout false

    def index
      return head :not_found unless OpenapiRails.configuration.ui_enabled

      config = OpenapiRails.configuration
      @schemas = config.schemas.keys.map(&:to_s)
      @default_schema = @schemas.first
      @ui_config = config.ui_config
      @schema_url = openapi_rails.schema_path(@default_schema, format: schema_format)

      render html: swagger_ui_html.html_safe
    end

    private

    def schema_format
      (OpenapiRails.configuration.schema_output_format == :json) ? :json : :yaml
    end

    def swagger_ui_html
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <title>#{@ui_config[:title] || "API Documentation"}</title>
          <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
          <style>
            html { box-sizing: border-box; overflow-y: scroll; }
            *, *:before, *:after { box-sizing: inherit; }
            body { margin: 0; background: #fafafa; }
          </style>
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
          <script>
            SwaggerUIBundle({
              url: "#{@schema_url}",
              dom_id: '#swagger-ui',
              deepLinking: true,
              presets: [
                SwaggerUIBundle.presets.apis,
                SwaggerUIBundle.SwaggerUIStandalonePreset
              ],
              layout: "BaseLayout",
              #{ui_config_js}
            });
          </script>
        </body>
        </html>
      HTML
    end

    def ui_config_js
      @ui_config.except(:title).map { |k, v|
        "#{k}: #{v.to_json}"
      }.join(",\n          ")
    end
  end
end
