# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[get_token validate_token callback]
  skip_before_action :require_login, only: %i[get_token validate_token callback]

  # GET /auth/get_token
  # Return user email for authenticated SSO user (for Chrome extensions)
  def get_token
    Rails.logger.info '=== AUTH GET_TOKEN CALLED ==='
    Rails.logger.info "Session user_id: #{session[:user_id]}"
    Rails.logger.info "Current user: #{current_user&.email || 'NOT AUTHENTICATED'}"
    Rails.logger.info "Request path: #{request.fullpath}"
    Rails.logger.info "Redirect URI param: #{params[:redirect_uri]}"

    # User is authenticated via SSO session
    if current_user
      Rails.logger.info "✅ User authenticated successfully: #{current_user.email}"

      # Check if redirect_uri is provided (Chrome extension flow)
      if params[:redirect_uri].present?
        # Chrome extension flow - redirect back with token
        redirect_uri = params[:redirect_uri]
        token = current_user.email # Using email as the token

        # Construct redirect URL with token parameter
        separator = redirect_uri.include?('?') ? '&' : '?'
        redirect_url = "#{redirect_uri}#{separator}token=#{CGI.escape(token)}"

        Rails.logger.info "Redirecting to Chrome extension: #{redirect_url}"
        redirect_to redirect_url, allow_other_host: true
      else
        # Legacy flow - render page with token (for old content script approach)
        Rails.logger.info 'No redirect_uri provided, rendering token page'
        # Render the page with current_user available
      end
    else
      Rails.logger.info '❌ User not authenticated, redirecting to login'
      # User not authenticated, redirect to login with return URL
      redirect_to new_session_path(redirect_to: request.fullpath)
    end
  rescue StandardError => e
    Rails.logger.error "Auth error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to root_path, alert: 'Authentication failed. Please try again.'
  end

  # GET /auth/callback
  # OAuth callback for Chrome extension (development mode)
  # This page is used with chrome.identity.launchWebAuthFlow for localhost development
  def callback
    Rails.logger.info '=== AUTH CALLBACK CALLED ==='
    Rails.logger.info "Current user: #{current_user&.email || 'NOT AUTHENTICATED'}"

    if current_user
      @token = current_user.email
      Rails.logger.info "✅ Callback with token: #{@token}"
      # Render the callback view
    else
      Rails.logger.info '❌ User not authenticated in callback'
      redirect_to new_session_path(redirect_to: request.fullpath)
    end
  rescue StandardError => e
    Rails.logger.error "Callback error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to root_path, alert: 'Authentication callback failed. Please try again.'
  end

  # GET /auth/validate
  # Validate current token and return user info
  def validate_token
    if current_user
      render json: {
        valid: true,
        user: {
          id: current_user.id,
          email: current_user.email
        },
        token_info: {
          last_used: current_user.api_tokens.where(active: true).maximum(:last_used),
          active_tokens: current_user.api_tokens.where(active: true).count
        }
      }
    else
      render json: {
        valid: false,
        error: 'Invalid or expired token'
      }, status: :unauthorized
    end
  end
end
