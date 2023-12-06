# spec/support/auth_helpers.rb
module AuthHelpers
  def sign_in(user = nil)
    user ||= create(:user)
    session[:user_id] = user.id
  end

  def api_sign_in(user = nil)
    user ||= create(:user)
    token = create(:api_token, user:)
    request.headers['Authorization'] = "Token #{token.token}"
  end
end