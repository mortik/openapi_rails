# frozen_string_literal: true

module OpenapiRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install openapi_rails: creates initializer, test helper, and component directory"

      def create_initializer
        template "initializer.rb.tt", "config/initializers/openapi_rails.rb"
      end

      def create_test_helper
        if rspec?
          template "openapi_helper.rb.tt", "spec/openapi_helper.rb"
        else
          template "openapi_helper.rb.tt", "test/openapi_helper.rb"
        end
      end

      def create_component_directories
        empty_directory "app/api_components/schemas"
        empty_directory "app/api_components/parameters"
        empty_directory "app/api_components/security_schemes"
      end

      def create_swagger_directory
        empty_directory "swagger"
      end

      def mount_engine
        route 'mount OpenapiRails::Engine => "/api-docs"'
      end

      private

      def rspec?
        File.exist?(File.join(destination_root, "spec"))
      end

      def app_name
        Rails.application.class.module_parent_name
      rescue
        "MyApp"
      end
    end
  end
end
