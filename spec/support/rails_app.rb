# frozen_string_literal: true

require "rails"
require "rails/generators"
require "action_controller/railtie"

# Minimal Rails application for testing
class TestApp < Rails::Application
  config.eager_load = false
  config.hosts.clear
  config.secret_key_base = "test_secret_key_base_for_openapi_rails"
end

TestApp.initialize!
