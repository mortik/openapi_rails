# frozen_string_literal: true

OpenapiRails::Engine.routes.draw do
  get "schemas", to: "schemas#index", as: :schemas
  get "schemas/:id", to: "schemas#show", as: :schema

  get "ui", to: "ui#index", as: :ui
end
