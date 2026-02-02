# frozen_string_literal: true

# Simplified OAuth flow for MCP remote setup
# User visits a URL, authorizes, and gets a token to paste into config
class McpOauthController < ApplicationController
  skip_before_action :require_login, only: [:connect, :authorize, :config]
  skip_before_action :verify_authenticity_token

  # GET /mcp/connect
  # Landing page for MCP OAuth flow
  def connect
    if logged_in?
      # User is already logged in, show authorization page
      # (connect.html.erb will be rendered by default)
    else
      # Redirect to login, then come back here
      session[:mcp_oauth_return_to] = mcp_connect_path
      redirect_to new_session_path, notice: 'Please login to connect an MCP client.'
    end
  end

  # POST /mcp/authorize
  # User authorizes the MCP client and gets a token
  def authorize
    unless logged_in?
      render json: { error: 'Not authenticated' }, status: :unauthorized
      return
    end

    # Create a long-lived API token for this MCP client
    token = ApiToken.create!(
      user: current_user,
      name: "MCP Client - #{params[:client_name] || 'Cursor/Claude'} - #{Time.current.strftime('%Y-%m-%d %H:%M')}",
      active: true
    )

    @token = token.token
    @fack_base_url = ENV['ROOT_URL'] || request.base_url
    
    render :show_token
  end

  # GET /mcp/config
  # Shows the full config snippet with the current user's token
  # Useful for getting started quickly
  def config
    unless logged_in?
      session[:mcp_oauth_return_to] = mcp_config_path
      redirect_to new_session_path, notice: 'Please login to get your MCP config.'
      return
    end

    # Find or create an MCP token for this user
    @token = current_user.api_tokens.where(active: true).where("name LIKE ?", "%MCP%").first
    
    unless @token
      @token = ApiToken.create!(
        user: current_user,
        name: "MCP Client - #{Time.current.strftime('%Y-%m-%d %H:%M')}",
        active: true
      )
    end

    @fack_base_url = ENV['ROOT_URL'] || request.base_url
  end
end
