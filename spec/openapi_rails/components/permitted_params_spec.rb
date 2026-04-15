# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Components::Base.permitted_params" do
  before { OpenapiRails::Components::Registry.instance.clear! }

  def create_component(name, &block)
    klass = Class.new
    stub_const(name, klass)
    klass.include(OpenapiRails::Components::Base)
    klass.class_eval(&block) if block
    klass
  end

  it "returns flat param list for simple properties" do
    comp = create_component("SimpleSchema") do
      schema(
        type: :object,
        properties: {
          name: {type: :string},
          email: {type: :string},
          age: {type: :integer}
        }
      )
    end

    expect(comp.permitted_params).to eq([:name, :email, :age])
  end

  it "returns empty array for schema without properties" do
    comp = create_component("EmptySchema") do
      schema(type: :object)
    end

    expect(comp.permitted_params).to eq([])
  end

  it "handles array of scalars" do
    comp = create_component("TagsSchema") do
      schema(
        type: :object,
        properties: {
          name: {type: :string},
          tags: {type: :array, items: {type: :string}}
        }
      )
    end

    expect(comp.permitted_params).to eq([:name, {tags: []}])
  end

  it "handles array of objects" do
    comp = create_component("NestedArraySchema") do
      schema(
        type: :object,
        properties: {
          items: {
            type: :array,
            items: {
              type: :object,
              properties: {
                id: {type: :integer},
                quantity: {type: :integer}
              }
            }
          }
        }
      )
    end

    expect(comp.permitted_params).to eq([{items: [:id, :quantity]}])
  end

  it "handles nested objects" do
    comp = create_component("AddressSchema") do
      schema(
        type: :object,
        properties: {
          name: {type: :string},
          address: {
            type: :object,
            properties: {
              street: {type: :string},
              city: {type: :string},
              zip: {type: :string}
            }
          }
        }
      )
    end

    expect(comp.permitted_params).to eq([:name, {address: [:street, :city, :zip]}])
  end

  it "handles deeply nested structures" do
    comp = create_component("DeepSchema") do
      schema(
        type: :object,
        properties: {
          user: {
            type: :object,
            properties: {
              name: {type: :string},
              address: {
                type: :object,
                properties: {
                  street: {type: :string}
                }
              }
            }
          }
        }
      )
    end

    expect(comp.permitted_params).to eq([{user: [:name, {address: [:street]}]}])
  end

  it "works with inherited schemas" do
    parent = create_component("ParentInput") do
      schema(type: :object, properties: {name: {type: :string}})
    end

    child = Class.new(parent)
    stub_const("ChildInput", child)
    child.schema(properties: {email: {type: :string}})

    expect(child.permitted_params).to eq([:name, :email])
  end
end
