# frozen_string_literal: true

require "spec_helper"
require "rack"
require "rack/test"

RSpec.describe OpenapiRails::Middleware::ResponseValidation do
  include Rack::Test::Methods

  let(:document) do
    {
      "openapi" => "3.1.0",
      "info" => {"title" => "Test", "version" => "1.0"},
      "paths" => {
        "/users" => {
          "get" => {
            "responses" => {
              "200" => {
                "description" => "OK",
                "content" => {
                  "application/json" => {
                    "schema" => {
                      "type" => "array",
                      "items" => {"$ref" => "#/components/schemas/User"}
                    }
                  }
                }
              }
            }
          }
        }
      },
      "components" => {
        "schemas" => {
          "User" => {
            "type" => "object",
            "required" => ["id", "name"],
            "properties" => {
              "id" => {"type" => "integer"},
              "name" => {"type" => "string"},
              "email" => {"type" => "string"}
            }
          }
        }
      }
    }
  end

  let(:resolver) { OpenapiRails::Middleware::SchemaResolver.new(document: document) }

  # Chain request validation (disabled, just sets env) -> response validation -> inner app
  def build_app(inner_app, mode: :enabled, validate_success_only: false)
    req_mw = OpenapiRails::Middleware::RequestValidation.new(inner_app, schema_resolver: resolver, mode: :disabled)
    described_class.new(req_mw, schema_resolver: resolver, mode: mode, validate_success_only: validate_success_only)
  end

  context "with valid responses" do
    let(:app) do
      build_app(->(_env) { [200, {"content-type" => "application/json"}, ['[{"id":1,"name":"Jane","email":"j@e.com"}]']] })
    end

    it "passes through" do
      get "/users"
      expect(last_response.status).to eq(200)
    end
  end

  context "with response missing required field" do
    let(:app) do
      build_app(->(_env) { [200, {"content-type" => "application/json"}, ['[{"email":"j@e.com"}]']] })
    end

    it "returns 500" do
      get "/users"
      expect(last_response.status).to eq(500)
      body = JSON.parse(last_response.body)
      expect(body["details"].first).to match(/required/i)
    end
  end

  context "with response having wrong field type" do
    let(:app) do
      build_app(->(_env) { [200, {"content-type" => "application/json"}, ['[{"id":"notanumber","name":"Jane"}]']] })
    end

    it "returns 500" do
      get "/users"
      expect(last_response.status).to eq(500)
      body = JSON.parse(last_response.body)
      expect(body["details"].first).to match(/type|integer/i)
    end
  end

  context "with response not matching array type" do
    let(:app) do
      build_app(->(_env) { [200, {"content-type" => "application/json"}, ['{"id":1,"name":"Jane"}']] })
    end

    it "returns 500" do
      get "/users"
      expect(last_response.status).to eq(500)
      body = JSON.parse(last_response.body)
      expect(body["details"].first).to match(/type|array/i)
    end
  end

  context "with $ref resolution" do
    let(:app) do
      # Valid response matching the $ref schema
      build_app(->(_env) { [200, {"content-type" => "application/json"}, ['[{"id":1,"name":"Jane"}]']] })
    end

    it "resolves $ref and validates against the referenced schema" do
      get "/users"
      expect(last_response.status).to eq(200)
    end
  end

  context "with disabled mode" do
    let(:app) do
      build_app(->(_env) { [200, {"content-type" => "application/json"}, ['{"invalid":true}']] }, mode: :disabled)
    end

    it "skips validation" do
      get "/users"
      expect(last_response.status).to eq(200)
    end
  end

  context "with warn_only mode" do
    let(:app) do
      build_app(->(_env) { [200, {"content-type" => "application/json"}, ['[{"email":"j@e.com"}]']] }, mode: :warn_only)
    end

    it "passes through but warns" do
      expect { get "/users" }.to output(/Response validation warnings/).to_stderr
      expect(last_response.status).to eq(200)
    end
  end

  context "with 204 responses" do
    let(:app) do
      build_app(->(_env) { [204, {}, []] })
    end

    it "skips validation" do
      get "/users"
      expect(last_response.status).to eq(204)
    end
  end

  context "with validate_success_only" do
    let(:app) do
      build_app(
        ->(_env) { [404, {"content-type" => "application/json"}, ['{"wrong":"shape"}']] },
        validate_success_only: true
      )
    end

    it "skips validation for error responses" do
      get "/users"
      expect(last_response.status).to eq(404)
    end
  end
end
