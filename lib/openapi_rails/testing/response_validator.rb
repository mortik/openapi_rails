# frozen_string_literal: true

module OpenapiRails
  module Testing
    class ResponseValidator
      def initialize(document_hash = nil)
        @document_hash = document_hash
        @schemer = nil
      end

      def validate(response_body:, status_code:, response_context:, content_type: "application/json")
        errors = []

        # Validate status code
        expected = response_context.status_code.to_s
        actual = status_code.to_s
        if actual != expected
          errors << "Expected status #{expected}, got #{actual}"
        end

        # Validate response body against schema
        if response_context.schema_definition && response_body
          schema_errors = validate_schema(response_body, response_context.schema_definition, content_type)
          errors.concat(schema_errors)
        end

        # Validate headers
        errors
      end

      def validate_against_document(response_body:, status_code:, path:, method:, content_type: "application/json")
        return [] unless @document_hash

        errors = []
        operation = @document_hash.dig("paths", path, method.to_s.downcase)
        return ["Operation not found: #{method.upcase} #{path}"] unless operation

        response_spec = operation.dig("responses", status_code.to_s)
        return ["Response #{status_code} not documented for #{method.upcase} #{path}"] unless response_spec

        schema = response_spec.dig("content", content_type, "schema")
        if schema && response_body
          schema_errors = validate_schema(response_body, schema, content_type)
          errors.concat(schema_errors)
        end

        errors
      end

      private

      def validate_schema(data, schema, _content_type)
        # If schema is a $ref within a document, use the document-aware schemer
        if @document_hash
          schemer = JSONSchemer.openapi(@document_hash)
          # Build a temporary schema that references the document
          begin
            result = schemer.validate_data(data, schema)
            return result.map { |e| format_error(e) }
          rescue StandardError
            # Fall through to standalone validation
          end
        end

        # Standalone schema validation
        begin
          s = JSONSchemer.schema(schema)
          result = s.validate(data).to_a
          result.map { |e| format_error(e) }
        rescue StandardError => e
          [e.message]
        end
      end

      def format_error(error)
        if error.is_a?(Hash)
          path = error["data_pointer"] || error["schema_pointer"] || ""
          msg = error["type"] || error["error"] || "validation failed"
          "#{path}: #{msg}".strip
        else
          error.to_s
        end
      end
    end
  end
end
