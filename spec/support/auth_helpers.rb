# spec/support/auth_helpers.rb
module AuthHelpers
  def sign_in(user)
    session[:user_id] = user.id
  end
end
