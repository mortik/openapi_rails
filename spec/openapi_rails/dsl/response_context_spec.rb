# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::DSL::ResponseContext do
  describe "#to_openapi" do
    it "builds a basic response" do
      ctx = described_class.new(200, "OK")
      result = ctx.to_openapi

      expect(result).to eq({ "description" => "OK" })
    end

    it "includes schema as JSON content" do
      ctx = described_class.new(200, "success")
      ctx.schema(type: :object, properties: { name: { type: :string } })

      result = ctx.to_openapi

      expect(result["content"]["application/json"]["schema"]).to eq({
        "type" => "object",
        "properties" => { "name" => { "type" => "string" } }
      })
    end

    it "uses custom produces content types" do
      ctx = described_class.new(200, "success")
      ctx.produces("text/csv")
      ctx.schema(type: :string)

      result = ctx.to_openapi

      expect(result["content"]).to have_key("text/csv")
      expect(result["content"]).not_to have_key("application/json")
    end

    it "includes headers" do
      ctx = described_class.new(200, "success")
      ctx.header("X-Rate-Limit", schema: { type: :integer }, description: "Rate limit")

      result = ctx.to_openapi

      expect(result["headers"]["X-Rate-Limit"]).to eq({
        "schema" => { "type" => "integer" },
        "description" => "Rate limit"
      })
    end

    it "includes examples" do
      ctx = described_class.new(200, "success")
      ctx.schema(type: :object)
      ctx.example("application/json", value: { name: "Jane" }, name: "basic")

      result = ctx.to_openapi

      expect(result["content"]["application/json"]["examples"]["basic"]["value"]).to eq({ name: "Jane" })
    end
  end

  describe "#status_code" do
    it "converts to string" do
      ctx = described_class.new(201, "created")
      expect(ctx.status_code).to eq("201")
    end
  end
end
