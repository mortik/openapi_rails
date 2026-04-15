# frozen_string_literal: true

require "spec_helper"
require_relative "../support/rails_app"
require "generators/openapi_rails/component/component_generator"
require "tmpdir"
require "securerandom"

RSpec.describe OpenapiRails::Generators::ComponentGenerator do
  let(:destination) { File.join(Dir.tmpdir, "openapi_rails_gen_#{SecureRandom.hex(4)}") }

  before { FileUtils.mkdir_p(destination) }
  after { FileUtils.rm_rf(destination) }

  def run_generator(args)
    described_class.start(args, destination_root: destination, shell: Thor::Shell::Basic.new)
  end

  context "with default type (schemas)" do
    it "creates the component file" do
      run_generator(%w[User])
      path = File.join(destination, "app/api_components/schemas/user.rb")
      expect(File.exist?(path)).to be true
      content = File.read(path)
      expect(content).to include("class Schemas::User")
      expect(content).to include("include OpenapiRails::Components::Base")
      expect(content).not_to include("component_type")
    end
  end

  context "with security_schemes type" do
    it "creates the component with correct type" do
      run_generator(%w[BearerAuth security_schemes])
      path = File.join(destination, "app/api_components/security_schemes/bearer_auth.rb")
      expect(File.exist?(path)).to be true
      content = File.read(path)
      expect(content).to include("class SecuritySchemes::BearerAuth")
      expect(content).to include("component_type :securitySchemes")
    end
  end

  context "with request_bodies type" do
    it "creates the component with correct type" do
      run_generator(%w[UserInput request_bodies])
      path = File.join(destination, "app/api_components/request_bodies/user_input.rb")
      expect(File.exist?(path)).to be true
      content = File.read(path)
      expect(content).to include("class RequestBodies::UserInput")
      expect(content).to include("component_type :requestBodies")
    end
  end
end
