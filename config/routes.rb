# frozen_string_literal: true

Rails.application.routes.draw do
  resources :messages
  resources :chats
  resources :assistants
  # Root route
  root 'questions#new' # Setting the questions new page as the root page

  # Auth routes
  resources :sessions, only: %i[new create destroy]
  get '/sessions/logout', to: 'sessions#logout'
  get '/sessions/set_debug', to: 'sessions#set_debug'
  # SAML Authentication
  get 'auth/saml/init', to: 'saml#init'
  post 'auth/saml/consume', to: 'saml#consume'
  get 'auth/saml/metadata', to: 'saml#metadata'

  # General Resources
  resources :questions
  resources :documents
  resources :api_tokens

  # Nested Resources
  resources :libraries do
    resources :library_users
    resources :documents
    member do
      get 'users'
    end
  end

  resources :delayed_jobs, only: %i[index destroy]

  # API Routes - Setting default format to JSON
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :documents
      resources :libraries
      resources :questions
    end
  end

  # Admin Routes
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
  end
end
