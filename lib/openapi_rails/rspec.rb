# frozen_string_literal: true

require "openapi_rails"
require_relative "adapters/rspec"

OpenapiRails::Adapters::RSpec.install!
