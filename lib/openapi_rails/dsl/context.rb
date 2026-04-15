# frozen_string_literal: true

module OpenapiRails
  module DSL
    class Context
      attr_reader :path_template, :operations, :path_parameters, :spec_name

      HTTP_METHODS = %i[get post put patch delete head options trace].freeze

      def initialize(path_template, spec_name: nil)
        @path_template = path_template
        @spec_name = spec_name
        @operations = {}
        @path_parameters = []
      end

      def parameter(attributes = {})
        param = deep_stringify(attributes)
        param["required"] = true if param["in"] == "path"
        @path_parameters << param
      end

      HTTP_METHODS.each do |method|
        define_method(method) do |summary = nil, &block|
          op = OperationContext.new(method, summary)
          # Copy path-level parameters to operation
          @path_parameters.each { |p| op.parameter(p) }
          op.instance_eval(&block) if block
          @operations[method.to_s] = op
          op
        end
      end

      def to_openapi
        result = {}

        if @path_parameters.any?
          result["parameters"] = @path_parameters
        end

        @operations.each do |verb, op|
          result[verb] = op.to_openapi
        end

        result
      end

      private

      def deep_stringify(value)
        case value
        when Hash
          value.each_with_object({}) { |(k, v), h| h[k.to_s] = deep_stringify(v) }
        when Array
          value.map { |v| deep_stringify(v) }
        when Symbol
          value.to_s
        else
          value
        end
      end
    end
  end
end
