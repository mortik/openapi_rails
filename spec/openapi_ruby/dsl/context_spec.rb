# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRuby::DSL::Context do
  describe "#to_openapi" do
    it "builds a path item with operations" do
      ctx = described_class.new("/users")
      ctx.get("List users") do
        response(200, "success") { schema(type: :array) }
      end

      result = ctx.to_openapi

      expect(result["get"]["summary"]).to eq("List users")
      expect(result["get"]["responses"]["200"]["description"]).to eq("success")
    end

    it "supports multiple HTTP methods" do
      ctx = described_class.new("/users")
      ctx.get("List") { response(200, "OK") }
      ctx.post("Create") { response(201, "Created") }

      result = ctx.to_openapi

      expect(result.keys).to include("get", "post")
    end

    it "propagates path-level parameters to operations" do
      ctx = described_class.new("/users/{id}")
      ctx.parameter(name: :id, in: :path, schema: {type: :integer})
      ctx.get("Get user") { response(200, "OK") }

      result = ctx.to_openapi

      # Path-level parameters are copied to operations, not output at path level
      expect(result).not_to have_key("parameters")
      expect(result["get"]["parameters"].length).to eq(1)
      expect(result["get"]["parameters"][0]["name"]).to eq("id")
      expect(result["get"]["parameters"][0]["required"]).to be true
    end

    it "copies path parameters to operations" do
      ctx = described_class.new("/users/{id}")
      ctx.parameter(name: :id, in: :path, schema: {type: :integer})
      ctx.get("Get user") { response(200, "OK") }

      op_params = ctx.to_openapi["get"]["parameters"]

      expect(op_params.any? { |p| p["name"] == "id" }).to be true
    end

    it "stores schema_name" do
      ctx = described_class.new("/users", schema_name: :public_api)

      expect(ctx.schema_name).to eq(:public_api)
    end
  end

  describe "HTTP methods" do
    OpenapiRuby::DSL::Context::HTTP_METHODS.each do |method|
      it "supports #{method}" do
        ctx = described_class.new("/test")
        ctx.send(method) { response(200, "OK") }

        expect(ctx.operations).to have_key(method.to_s)
      end
    end
  end
end
