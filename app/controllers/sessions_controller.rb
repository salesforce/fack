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

  def google_oauth2
    auth = request.env['omniauth.auth']
    user = current_user # Assuming you have a current_user method
    google_authorization = user.google_authorization || user.create_google_authorization

    google_authorization.update(
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      expires_at: Time.at(auth.credentials.expires_at)
    )

    # Redirect to the desired page after successful authorization
    redirect_to root_path, notice: 'Google Docs connected successfully!'
  end
end
