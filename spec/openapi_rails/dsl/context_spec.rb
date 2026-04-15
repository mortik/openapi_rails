# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::DSL::Context do
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

    it "includes path-level parameters" do
      ctx = described_class.new("/users/{id}")
      ctx.parameter(name: :id, in: :path, schema: { type: :integer })
      ctx.get("Get user") { response(200, "OK") }

      result = ctx.to_openapi

      expect(result["parameters"].length).to eq(1)
      expect(result["parameters"][0]["name"]).to eq("id")
      expect(result["parameters"][0]["required"]).to be true
    end

    it "copies path parameters to operations" do
      ctx = described_class.new("/users/{id}")
      ctx.parameter(name: :id, in: :path, schema: { type: :integer })
      ctx.get("Get user") { response(200, "OK") }

      op_params = ctx.to_openapi["get"]["parameters"]

      expect(op_params.any? { |p| p["name"] == "id" }).to be true
    end

    it "stores spec_name" do
      ctx = described_class.new("/users", spec_name: :public_api)

      expect(ctx.spec_name).to eq(:public_api)
    end
  end

  describe "HTTP methods" do
    OpenapiRails::DSL::Context::HTTP_METHODS.each do |method|
      it "supports #{method}" do
        ctx = described_class.new("/test")
        ctx.send(method) { response(200, "OK") }

        expect(ctx.operations).to have_key(method.to_s)
      end
    end
  end
end
