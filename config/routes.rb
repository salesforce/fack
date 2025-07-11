Rails.application.routes.draw do
  resources :webhooks
  resources :messages
  resources :chats do
    resources :messages
  end
  resources :assistants do
    resources :chats, only: %i[create new index]
    get 'clone', on: :member

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
      get 'download'
    end
  end

  resources :delayed_jobs, only: %i[index destroy] do
    member do
      post :run_now
    end
  end

  # API Routes - Setting default format to JSON
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :documents
      resources :libraries
      resources :questions
      resources :chats do
        resources :messages
      end
      resources :assistants do
        # Adding the pdwebhook route for a specific assistant
        member do
          post 'pdwebhook'
        end
      end

      resources :webhooks do
        member do
          post 'receive'
        end
      end
    end
  end

  # Admin Routes
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
  end

  root 'dashboard#index' # Setting the dashboard as the root page

  post '/slack/events', to: 'slack#events'
  post '/slack/interactivity', to: 'slack#interactivity'

  get '/auth/:provider/callback', to: 'sessions#google_oauth2'
  get '/auth/failure', to: redirect('/') # Handle authentication failures

  mount ActionCable.server => '/cable'
end
