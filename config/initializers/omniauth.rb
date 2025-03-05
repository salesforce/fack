Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV.fetch('GOOGLE_CLIENT_ID', nil), ENV.fetch('GOOGLE_CLIENT_SECRET', nil),
           {
             scope: 'https://www.googleapis.com/auth/documents, profile, email',
             prompt: 'select_account',
             skip_jwt: true
           }
end
OmniAuth.config.allowed_request_methods = %i[get]
