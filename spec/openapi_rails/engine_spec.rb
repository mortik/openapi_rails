# frozen_string_literal: true

require "spec_helper"
require_relative "../support/rails_app"
require "openapi_rails/engine"

RSpec.describe OpenapiRails::Engine do
  it "is a Rails::Engine" do
    expect(described_class.superclass).to eq(Rails::Engine)
  end

  it "has an isolated namespace" do
    expect(described_class.isolated?).to be true
  end
end
