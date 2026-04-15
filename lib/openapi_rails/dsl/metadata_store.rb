# frozen_string_literal: true

module OpenapiRails
  module DSL
    class MetadataStore
      class << self
        def instance
          @instance ||= new
        end

        delegate :register, :contexts_for, :all_contexts, :clear!, to: :instance
      end

      def initialize
        @contexts = []
      end

      def register(context)
        @contexts << context
      end

      def contexts_for(schema_name)
        schema_name = schema_name&.to_sym
        @contexts.select { |c| c.schema_name.nil? || c.schema_name&.to_sym == schema_name }
      end

      def all_contexts
        @contexts.dup
      end

      def clear!
        @contexts = []
      end
    end
  end
end
