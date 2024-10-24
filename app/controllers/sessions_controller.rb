class SessionsController < ApplicationController
  skip_before_action :require_login

  def new; end

  def create
    user = User.find_by_email(params[:session][:email])
    if user&.authenticate(params[:session][:password])
      login_user(user)
      redirect_back(fallback_location: root_path)
    else
      redirect_to new_session_url, notice: 'Error logging in.'
    end
  end

  def set_debug
    session[:debug] = params[:debug]
    redirect_back(fallback_location: root_url, notice: "Debug mode: #{session[:debug]}")
  end

  def set_beta
    session[:beta] = params[:beta]
    redirect_back(fallback_location: root_url, notice: "Beta mode: #{session[:beta]}")
  end

  def logout
    Rails.logger.debug "Session before Logout: #{session.to_hash}"
    Rails.logger.info "Logout called: #{request.referrer}, #{request.user_agent}, #{request.remote_ip}, #{session.to_hash}"

    session[:user_id] = nil
    redirect_back(fallback_location: root_url)
  end
end
