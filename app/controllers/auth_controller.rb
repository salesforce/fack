# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:get_token]
  skip_before_action :require_login, only: [:get_token]

  # GET /auth/get_token
  # Generate and display API token for authenticated SSO user (for Chrome extensions)
  def get_token
    Rails.logger.info "=== AUTH GET_TOKEN CALLED ==="
    Rails.logger.info "Current user: #{current_user&.email || 'NOT AUTHENTICATED'}"
    
    # User is authenticated via SSO session, generate token
    if current_user
      # Create or find an existing active token for this user
      @api_token = current_user.api_tokens.where(active: true, name: "Chrome Extension Token").first
      
      if @api_token.nil?
        # Create a new token if none exists
        @api_token = current_user.api_tokens.create!(
          name: "Chrome Extension Token",
          active: true
        )
        Rails.logger.info "Created new token: #{@api_token.token}"
      end
      
      Rails.logger.info "Displaying token: #{@api_token.token}"
      # Render the token display view directly
    else
      # User not authenticated, redirect to SSO login
      redirect_to auth_saml_init_path
    end
  rescue StandardError => e
    Rails.logger.error "Auth error: #{e.message}"
    redirect_to root_path, alert: 'Authentication failed. Please try again.'
  end

end
