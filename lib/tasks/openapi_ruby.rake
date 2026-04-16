# frozen_string_literal: true

namespace :openapi_ruby do
  desc "Generate OpenAPI schema files from spec definitions and components"
  task generate: :environment do
    pattern = ENV.fetch("PATTERN", "spec/**/*_spec.rb")
    command = "bundle exec rspec --pattern '#{pattern}' --dry-run --order defined"
    puts "Generating OpenAPI schemas..."
    system(command) || abort("Schema generation failed")
  end
end
