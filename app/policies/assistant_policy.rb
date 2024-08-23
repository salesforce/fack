# frozen_string_literal: true

class AssistantPolicy < ApplicationPolicy
  attr_reader :user, :assistant

  def initialize(user, assistant)
    @user = user
    @assistant = assistant
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
