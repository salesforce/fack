class ApiTokenPolicy < ApplicationPolicy
  attr_reader :user, :api_token

  def initialize(user, api_token)
    @user = user
    @api_token = api_token
  end

  # Example policy for showing an ApiToken
  def show?
    user.admin? || api_token.user_id == user.id
  end

  def index?
    true
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || api_token.user_id == user.id
  end

  def destroy?
    user.admin? || api_token.user_id == user.id
  end

  # Scope class defines which api tokens are visible to the user
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
