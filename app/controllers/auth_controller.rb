# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:get_token]
  skip_before_action :require_login, only: [:get_token]

  # GET /auth/get_token
  # Generate and display API token for authenticated SSO user (for Chrome extensions)
  # For chrome, we don't need to generate a token, we just need to know the user is authenticated
  def get_token
    Rails.logger.info '=== AUTH GET_TOKEN CALLED ==='
    Rails.logger.info "Current user: #{current_user&.email || 'NOT AUTHENTICATED'}"

    # User is authenticated via SSO session, generate token
    if current_user
      Rails.logger.info "User authenticated for browser. #{current_user.email}"
    else
      # User not authenticated, redirect to SSO login
      redirect_to auth_saml_init_path
    end
  rescue StandardError => e
    Rails.logger.error "Auth error: #{e.message}"
    redirect_to root_path, alert: 'Authentication failed. Please try again.'
  end
end
