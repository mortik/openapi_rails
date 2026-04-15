# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/class/attribute"
require "active_support/core_ext/hash/deep_merge"
require "active_support/core_ext/hash/keys"
require "active_support/core_ext/object/deep_dup"
require "active_support/core_ext/module/delegation"
require "active_support/core_ext/string/inflections"
require "json_schemer"
require "yaml"

require_relative "openapi_rails/version"
require_relative "openapi_rails/errors"
require_relative "openapi_rails/configuration"

module OpenapiRails
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

require_relative "openapi_rails/core/document"
require_relative "openapi_rails/core/document_builder"
require_relative "openapi_rails/core/ref_resolver"
require_relative "openapi_rails/components/key_transformer"
require_relative "openapi_rails/components/registry"
require_relative "openapi_rails/components/base"
require_relative "openapi_rails/components/loader"
require_relative "openapi_rails/dsl/response_context"
require_relative "openapi_rails/dsl/operation_context"
require_relative "openapi_rails/dsl/context"
require_relative "openapi_rails/dsl/metadata_store"
require_relative "openapi_rails/testing/request_builder"
require_relative "openapi_rails/testing/response_validator"
require_relative "openapi_rails/testing/assertions"
require_relative "openapi_rails/testing/coverage"
require_relative "openapi_rails/generator/schema_writer"
require_relative "openapi_rails/middleware/path_matcher"
require_relative "openapi_rails/middleware/coercion"
require_relative "openapi_rails/middleware/error_handler"
require_relative "openapi_rails/middleware/schema_resolver"
require_relative "openapi_rails/middleware/request_validation"
require_relative "openapi_rails/middleware/response_validation"
require_relative "openapi_rails/controller_helpers"
require_relative "openapi_rails/engine" if defined?(Rails::Engine)
