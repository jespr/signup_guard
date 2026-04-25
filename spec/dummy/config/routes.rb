# frozen_string_literal: true

Rails.application.routes.draw do
  resources :signups, only: [:create]
  resources :widgets, only: [:create]
  get "pending_review", to: "signups#pending_review", as: :pending_review_users
end
