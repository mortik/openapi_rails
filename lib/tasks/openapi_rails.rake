# frozen_string_literal: true

namespace :openapi_rails do
  desc "Generate OpenAPI spec files from test definitions and components"
  task generate: :environment do
    require "openapi_rails"
    OpenapiRails::Generator::SpecWriter.generate_all!
  end
end
