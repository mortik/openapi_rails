# frozen_string_literal: true

OpenapiRails::Engine.routes.draw do
  get "specs", to: "specs#index", as: :specs
  get "specs/:id", to: "specs#show", as: :spec

  get "ui", to: "ui#index", as: :ui
end
