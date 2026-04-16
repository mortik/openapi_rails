# frozen_string_literal: true

module OpenapiRuby
  module Components
    module KeyTransformer
      module_function

      def camelize_keys(hash)
        transform_keys(hash) { |key| camelize(key) }
      end

      def transform_keys(value, parent_key: nil, &block)
        case value
        when Hash
          value.each_with_object({}) do |(k, v), result|
            new_key = block.call(k.to_s)
            result[new_key] = transform_keys(v, parent_key: k.to_s, &block)
          end
        when Array
          if parent_key == "required"
            # Values in "required" arrays are property names that must also be transformed
            value.map { |v| v.is_a?(String) ? block.call(v) : transform_keys(v, &block) }
          else
            value.map { |v| transform_keys(v, &block) }
          end
        else
          value
        end
      end

      def camelize(key)
        key = key.to_s
        return key if key.start_with?("$")

        # Preserve leading underscore prefix (e.g., _destroy stays _destroy)
        prefix = key.start_with?("_") ? "_" : ""
        stripped = key.delete_prefix("_")

        parts = stripped.split("_")
        "#{prefix}#{parts[0]}#{parts[1..].map(&:capitalize).join}"
      end
    end
  end
end
