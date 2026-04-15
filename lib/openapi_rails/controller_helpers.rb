# frozen_string_literal: true

module OpenapiRails
  module ControllerHelpers
    def openapi_permit(component_class, key: nil)
      permitted = component_class.permitted_params
      source = key ? params.require(key) : params
      source.permit(*permitted)
    end
  end
end
