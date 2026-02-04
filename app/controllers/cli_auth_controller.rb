# frozen_string_literal: true

class CliAuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  # GET /cli/authorize?state=RANDOM&port=9090
  def new
    # User must be logged in to authorize CLI
    unless current_user
      session[:return_to] = request.original_url
      redirect_to new_session_path, notice: 'Please login to authorize CLI'
      return
    end

    @state = params[:state]
    @port = params[:port] || '9090'

    # Validate state parameter exists
    unless @state.present?
      render plain: 'Error: Missing state parameter', status: :bad_request
      return
    end

    # Validate port
    unless valid_port?(@port)
      render plain: 'Error: Invalid port number', status: :bad_request
      return
    end

    # Show authorization page
  end

  # POST /cli/authorize
  def create
    @state = params[:state]
    @port = params[:port] || '9090'

    # Validate port
    unless valid_port?(@port)
      render plain: 'Error: Invalid port number', status: :bad_request
      return
    end

    # Create new API token for CLI
    @api_token = ApiToken.new(
      user: current_user,
      name: "CLI Token - #{Time.current.strftime('%Y-%m-%d %H:%M')}",
      source: 'cli'
    )

    if @api_token.save
      # Redirect to localhost with token
      redirect_url = "http://127.0.0.1:#{@port}/callback?token=#{@api_token.token}&state=#{@state}"
      redirect_to redirect_url, allow_other_host: true
    else
      flash[:error] = 'Failed to create token'
      render :new, status: :unprocessable_entity
    end
  end

  private

  def valid_port?(port)
    # Only allow ports between 1024 and 65535 (non-privileged ports)
    port.to_i.between?(1024, 65535)
  end
end
