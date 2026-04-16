# frozen_string_literal: true

module OpenapiRuby
  module Components
    class Loader
      attr_reader :paths

      def initialize(paths: nil, scope: nil)
        @paths = paths || OpenapiRuby.configuration.component_paths
        @scope = scope&.to_sym
      end

      def load!
        define_namespace_modules!
        load_component_files!
        self
      end

      def to_openapi_hash
        Registry.instance.to_openapi_hash(scope: @scope)
      end

      def schemas
        filter_type(:schemas)
      end

      def parameters
        filter_type(:parameters)
      end

      def security_schemes
        filter_type(:securitySchemes)
      end

      def request_bodies
        filter_type(:requestBodies)
      end

      def responses
        filter_type(:responses)
      end

      def headers
        filter_type(:headers)
      end

      def examples
        filter_type(:examples)
      end

      def links
        filter_type(:links)
      end

      def callbacks
        filter_type(:callbacks)
      end

      private

      def define_namespace_modules!
        @paths.each do |path|
          expanded = File.expand_path(path)
          next unless Dir.exist?(expanded)

          Dir.glob(File.join(expanded, "**/")).each do |dir_path|
            relative = dir_path.sub("#{expanded}/", "").chomp("/")
            next if relative.empty?

            const_name = relative.camelize
            const_name.split("::").inject(Object) do |parent, name|
              if parent.const_defined?(name, false)
                parent.const_get(name, false)
              else
                parent.const_set(name, Module.new)
              end
            end
          end
        end
      end

      def load_component_files!
        scope_paths = OpenapiRuby.configuration.component_scope_paths

        # Collect all files with their base paths, then sort globally by relative
        # path to ensure consistent load order across multiple base paths.
        # This prevents cross-directory inheritance issues (e.g., a subclass in
        # packs/ai_feedback loading before its superclass in packs/api).
        all_files = collect_all_files

        if scope_paths.any?
          load_with_scope_inference(all_files, scope_paths)
        else
          all_files.each { |entry| require entry[:file] }
        end
      end

      def collect_all_files
        files = []
        @paths.each do |base_path|
          expanded = File.expand_path(base_path)
          next unless Dir.exist?(expanded)

          Dir[File.join(expanded, "**", "*.rb")].each do |file|
            relative = file.sub("#{expanded}/", "")
            files << {file: file, base_path: expanded, relative: relative}
          end
        end
        files.sort_by { |entry| entry[:relative] }
      end

      def load_with_scope_inference(all_files, scope_paths)
        all_files.each do |entry|
          inferred_scope = infer_scope(entry[:relative], scope_paths)

          registered_before = Registry.instance.all_registered_classes.dup
          require entry[:file]
          registered_after = Registry.instance.all_registered_classes

          new_classes = registered_after - registered_before
          new_classes.each do |klass|
            next if klass._component_scopes_explicitly_set

            if inferred_scope == :shared
              klass._component_scopes = []
            elsif inferred_scope
              Registry.instance.unregister(klass)
              klass._component_scopes = [inferred_scope]
              Registry.instance.register(klass)
            end
          end
        end
      end

      def infer_scope(relative_path, scope_paths)
        scope_paths.sort_by { |prefix, _| -prefix.length }.each do |prefix, scope|
          return scope&.to_sym if relative_path.start_with?("#{prefix}/")
        end
        nil
      end

      def filter_type(type)
        to_openapi_hash[type.to_s] || {}
      end
    end
  end
end
