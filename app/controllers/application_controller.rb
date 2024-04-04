class ApplicationController < ActionController::Base
  include Pundit::Authorization

  protect_from_forgery with: :exception
  helper_method :current_user, :logged_in?, :current_user_is_admin?

  # Make sure all requests are authorized
  before_action :require_login, except: %i[init consume]

  def require_login
    # check if request is authorized
    return if authorized?

    handle_bad_authentication
  end

  def authorized?
    # We allow UI auth to access the API for convenience in testing from a browswer
    # In theory, someone could access the UI with an API token, but its more complicated.
    ui_authenticated? || api_authenticated?
  end

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def login_user(user)
    session[:user_id] = user.id
    user.update(last_login: DateTime.now)
  end

  def current_user_is_admin?
    current_user.admin?
  end

  def logged_in?
    !!current_user
  end

  def api_authenticated?
    authenticate_api_with_token
  end

  def authenticate_api_with_token
    authenticate_with_http_token do |token, _options|
      current_api_token = ApiToken.where(active: true).find_by_token(token)

      if current_api_token
        @current_user = current_api_token.user
        current_api_token.last_used = DateTime.now
        current_api_token.save!

        session[:user_id] = @current_user.id

        return true
      end
    end
  end

  def handle_bad_authentication
    if request.format.json?
      render json: { message: 'Bad credentials' }, status: :unauthorized
    else
      redirect_to new_session_path, notice: 'Please login to view this page.'
    end
  end

  def handle_bad_authortization
    if request.format.json?
      render json: { message: 'Permission denied.' }, status: :unauthorized
    else
      redirect_to root_url,
                  notice: 'Permission denied.  Please contact an admin if you believe this message is incorrect.'
    end
  end

  def ui_authenticated?
    # Kill switch for SAML.
    # if ENV['DISABLE_SAML'] == 'true' && request.format.html?
    #  session[:authenticated] = true
    # end

    !current_user.nil?
  end
end
