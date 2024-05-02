# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login

  def new; end

  def create
    user = User.find_by_email(params[:session][:email])
    if user&.authenticate(params[:session][:password])
      login_user(user)
      redirect_to root_path
    else
      redirect_to new_session_url, notice: 'Error logging in.'
    end
  end

  def set_debug
    session[:debug] = params[:debug]
    redirect_to root_url, notice: "Debug set: #{session[:debug]}"
  end

  def logout
    session[:user_id] = nil
    redirect_to root_url
  end
end
