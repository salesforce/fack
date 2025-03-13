# frozen_string_literal: true

class WebhookPolicy < ApplicationPolicy
  attr_reader :user, :webhook

  def initialize(user, webhook)
    @user = user
    @webhook = webhook
  end

  # Example policy for showing an ApiToken
  def show?
    user.admin?
  end

  def index?
    user.admin?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end
