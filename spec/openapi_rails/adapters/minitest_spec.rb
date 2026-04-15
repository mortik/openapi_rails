# frozen_string_literal: true

require "spec_helper"
require "openapi_rails/adapters/minitest"

RSpec.describe OpenapiRails::Adapters::Minitest::DSL do
  let(:test_class) do
    klass = Class.new do
      include OpenapiRails::Adapters::Minitest::DSL
    end
    stub_const("TestIntegration", klass)
    klass
  end

  describe ".openapi_schema" do
    it "sets the schema name" do
      test_class.openapi_schema(:public_api)
      expect(test_class._openapi_schema_name).to eq(:public_api)
    end
  end

  describe ".api_path" do
    it "creates and registers a DSL context" do
      test_class.api_path("/users") do
        get "List users" do
          response(200, "success") { schema(type: :array) }
        end
      end

      expect(test_class._openapi_contexts.length).to eq(1)
      expect(test_class._openapi_contexts.first.path_template).to eq("/users")
    end

    it "registers context in metadata store" do
      test_class.api_path("/posts") do
        get "List posts" do
          response(200, "OK")
        end
      end

      contexts = OpenapiRails::DSL::MetadataStore.all_contexts
      expect(contexts.any? { |c| c.path_template == "/posts" }).to be true
    end

    it "uses the configured schema name" do
      test_class.openapi_schema(:admin_api)
      test_class.api_path("/admin") do
        get { response(200, "OK") }
      end

      context = test_class._openapi_contexts.last
      expect(context.schema_name).to eq(:admin_api)
    end

    it "supports full operation DSL" do
      test_class.api_path("/users") do
        post "Create user" do
          tags "Users"
          consumes "application/json"
          request_body(
            required: true,
            content: {
              "application/json" => {
                schema: {"$ref" => "#/components/schemas/UserInput"}
              }
            }
          )
          response(201, "created") { schema(type: :object) }
          response(422, "validation error") { schema(type: :object) }
        end
      end

      context = test_class._openapi_contexts.last
      op = context.operations["post"]
      expect(op.summary).to eq("Create user")
      expect(op.responses.keys).to contain_exactly("201", "422")
    end
  end

  describe "path expansion" do
    it "substitutes path parameters" do
      instance = test_class.new
      path = instance.send(:expand_path, "/users/{id}/posts/{post_id}", {id: 42, post_id: 7})
      expect(path).to eq("/users/42/posts/7")
    end

    it "handles string keys" do
      instance = test_class.new
      path = instance.send(:expand_path, "/users/{id}", {"id" => 99})
      expect(path).to eq("/users/99")
    end
  end
end
