# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"
require "securerandom"

RSpec.describe OpenapiRails::Generator::SpecWriter do
  let(:output_dir) { File.join(Dir.tmpdir, "openapi_rails_test_#{SecureRandom.hex(4)}") }

  before do
    OpenapiRails::DSL::MetadataStore.clear!
    OpenapiRails.configure do |config|
      config.spec_output_dir = output_dir
      config.spec_output_format = :yaml
      config.specs = {
        public_api: {
          info: { title: "Test API", version: "1.0.0" },
          servers: [{ url: "https://api.example.com" }]
        }
      }
    end
  end

  after do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  end

  describe "#write!" do
    it "generates a YAML spec file" do
      ctx = OpenapiRails::DSL::Context.new("/health", spec_name: :public_api)
      ctx.get("Health check") { response(200, "OK") }
      OpenapiRails::DSL::MetadataStore.register(ctx)

      writer = described_class.new(:public_api, OpenapiRails.configuration.specs[:public_api])
      path = writer.write!

      expect(File.exist?(path)).to be true
      content = YAML.safe_load(File.read(path))
      expect(content["openapi"]).to eq("3.1.0")
      expect(content["info"]["title"]).to eq("Test API")
      expect(content["paths"]["/health"]["get"]["summary"]).to eq("Health check")
    end

    it "generates a JSON spec file" do
      OpenapiRails.configuration.spec_output_format = :json

      ctx = OpenapiRails::DSL::Context.new("/health", spec_name: :public_api)
      ctx.get("Health check") { response(200, "OK") }
      OpenapiRails::DSL::MetadataStore.register(ctx)

      writer = described_class.new(:public_api, OpenapiRails.configuration.specs[:public_api])
      path = writer.write!

      expect(path).to end_with(".json")
      content = JSON.parse(File.read(path))
      expect(content["openapi"]).to eq("3.1.0")
    end

    it "includes components from registry" do
      OpenapiRails::Components::Registry.instance.clear!

      klass = Class.new
      stub_const("Schemas::TestModel", klass)
      klass.include OpenapiRails::Components::Base
      klass.schema(type: :object, properties: { id: { type: :integer } })

      ctx = OpenapiRails::DSL::Context.new("/test", spec_name: :public_api)
      ctx.get { response(200, "OK") }
      OpenapiRails::DSL::MetadataStore.register(ctx)

      writer = described_class.new(:public_api, OpenapiRails.configuration.specs[:public_api])
      path = writer.write!

      content = YAML.safe_load(File.read(path))
      expect(content["components"]["schemas"]).to have_key("TestModel")
    end
  end

  describe "#build_document" do
    it "merges paths from multiple contexts" do
      ctx1 = OpenapiRails::DSL::Context.new("/users", spec_name: :public_api)
      ctx1.get("List") { response(200, "OK") }
      ctx2 = OpenapiRails::DSL::Context.new("/posts", spec_name: :public_api)
      ctx2.get("List") { response(200, "OK") }

      OpenapiRails::DSL::MetadataStore.register(ctx1)
      OpenapiRails::DSL::MetadataStore.register(ctx2)

      writer = described_class.new(:public_api, OpenapiRails.configuration.specs[:public_api])
      doc = writer.build_document

      expect(doc.to_h["paths"].keys).to contain_exactly("/users", "/posts")
    end
  end

  describe ".generate_all!" do
    it "generates files for all configured specs" do
      ctx = OpenapiRails::DSL::Context.new("/health", spec_name: :public_api)
      ctx.get { response(200, "OK") }
      OpenapiRails::DSL::MetadataStore.register(ctx)

      described_class.generate_all!

      expect(File.exist?(File.join(output_dir, "public_api.yaml"))).to be true
    end

    it "warns when no specs configured" do
      OpenapiRails.configuration.specs = {}

      expect { described_class.generate_all! }.to output(/No specs configured/).to_stderr
    end
  end
end
