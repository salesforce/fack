Rails.application.routes.draw do
  resources :messages
  resources :chats do
    resources :messages
  end
  resources :assistants do
    resources :chats, only: %i[create new]

    # Adding the import route for all assistants
    collection do
      post 'import'
      get 'import'
    end
  end

  # Auth routes
  resources :sessions, only: %i[new create]
  get '/sessions/set_debug', to: 'sessions#set_debug'
  get '/sessions/set_beta', to: 'sessions#set_beta'
  get '/sessions/logout', to: 'sessions#logout', as: :logout

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

  root 'questions#new' # Setting the questions new page as the root page
end
