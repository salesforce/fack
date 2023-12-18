Rails.application.routes.draw do
  resources :api_tokens
  resources :sessions, only: [:new, :create, :destroy]
  #resources :users, only: [:new, :create] # For registration

  get '/sessions/logout', to: 'sessions#logout'
  get '/sessions/set_debug', to: 'sessions#set_debug'

  root 'questions#new' # Setting the login page as the root page

  resources :libraries do
    resources :documents
  end
  
  resources :questions
  resources :documents

  # API Routes
  namespace :api, :defaults => {:format => :json} do
    namespace :v1 do
      resources :documents
      resources :libraries
      resources :questions
    end
  end

  
  get 'auth/saml/init', to: 'saml#init'
  post 'auth/saml/consume', to: 'saml#consume'
  get 'auth/saml/metadata', to: 'saml#metadata'

end
