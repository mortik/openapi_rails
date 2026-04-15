# frozen_string_literal: true

module OpenapiRails
  module Generator
    class SpecWriter
      def self.generate_all!
        config = OpenapiRails.configuration

        if config.specs.empty?
          warn "[openapi_rails] No specs configured, skipping generation"
          return
        end

        config.specs.each do |name, spec_config|
          new(name, spec_config).write!
        end
      end

      def initialize(spec_name, spec_config)
        @spec_name = spec_name
        @spec_config = spec_config
      end

      def write!
        document = build_document
        output_path = File.join(output_dir, filename)
        FileUtils.mkdir_p(output_dir)
        File.write(output_path, format_output(document))
        output_path
      end

      def build_document
        builder = Core::DocumentBuilder.new(@spec_config)

        # Merge paths from DSL metadata
        DSL::MetadataStore.contexts_for(@spec_name).each do |context|
          builder.add_path(context.path_template, context.to_openapi)
        end

        # Merge components from registry
        scope = @spec_config[:component_scope]
        components = Components::Registry.instance.to_openapi_hash(scope: scope)
        builder.merge_components(components)

        builder.build
      end

      private

      def output_dir
        OpenapiRails.configuration.spec_output_dir
      end

      def filename
        ext = OpenapiRails.configuration.spec_output_format == :json ? "json" : "yaml"
        "#{@spec_name}.#{ext}"
      end

      def format_output(document)
        if OpenapiRails.configuration.spec_output_format == :json
          document.to_json
        else
          document.to_yaml
        end
      end
    end
  end
end
