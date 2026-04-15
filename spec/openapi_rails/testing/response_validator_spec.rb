# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenapiRails::Testing::ResponseValidator do
  describe "#validate" do
    it "returns no errors for matching status and schema" do
      response_ctx = OpenapiRails::DSL::ResponseContext.new(200, "OK")
      response_ctx.schema(type: "object", properties: { name: { type: "string" } })

      validator = described_class.new
      errors = validator.validate(
        response_body: { "name" => "Jane" },
        status_code: 200,
        response_context: response_ctx
      )

      expect(errors).to be_empty
    end

    it "returns error for wrong status code" do
      response_ctx = OpenapiRails::DSL::ResponseContext.new(200, "OK")

      validator = described_class.new
      errors = validator.validate(
        response_body: nil,
        status_code: 404,
        response_context: response_ctx
      )

      expect(errors).to include(/Expected status 200, got 404/)
    end

    it "returns schema errors for invalid body" do
      response_ctx = OpenapiRails::DSL::ResponseContext.new(200, "OK")
      response_ctx.schema(type: "object", required: ["name"], properties: { name: { type: "string" } })

      validator = described_class.new
      errors = validator.validate(
        response_body: { "age" => 30 },
        status_code: 200,
        response_context: response_ctx
      )

      expect(errors.length).to be > 0
    end

    it "skips schema validation when no schema defined" do
      response_ctx = OpenapiRails::DSL::ResponseContext.new(204, "No Content")

      validator = described_class.new
      errors = validator.validate(
        response_body: nil,
        status_code: 204,
        response_context: response_ctx
      )

      expect(errors).to be_empty
    end
  end
end
