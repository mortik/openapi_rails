# frozen_string_literal: true

require "spec_helper"
require_relative "../support/rails_app"
require "action_controller"

RSpec.describe OpenapiRails::ControllerHelpers do
  before { OpenapiRails::Components::Registry.instance.clear! }

  let(:component) do
    klass = Class.new
    stub_const("Schemas::TestInput", klass)
    klass.include(OpenapiRails::Components::Base)
    klass.schema(
      type: :object,
      properties: {
        name: {type: :string},
        email: {type: :string}
      }
    )
    klass
  end

  let(:controller_class) do
    comp = component
    Class.new(ActionController::Base) do
      include OpenapiRails::ControllerHelpers

      define_method(:test_action) do
        permitted = openapi_permit(comp)
        render json: permitted.to_h
      end
    end
  end

  describe "#openapi_permit" do
    it "permits params based on component schema" do
      raw_params = ActionController::Parameters.new(name: "Jane", email: "j@e.com", admin: true)
      controller_class.new

      # Simulate what the helper does
      permitted = raw_params.permit(*component.permitted_params)

      expect(permitted.to_h).to eq({"name" => "Jane", "email" => "j@e.com"})
      expect(permitted.to_h).not_to have_key("admin")
    end

    it "works with the key option" do
      raw_params = ActionController::Parameters.new(user: {name: "Jane", email: "j@e.com", admin: true})

      permitted = raw_params.require(:user).permit(*component.permitted_params)

      expect(permitted.to_h).to eq({"name" => "Jane", "email" => "j@e.com"})
    end
  end
end
