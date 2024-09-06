# frozen_string_literal: true

class AssistantPolicy < ApplicationPolicy
  attr_reader :user, :assistant

  def initialize(user, assistant)
    @user = user
    @assistant = assistant
  end

  def create?
    user.admin? || user.editor?
  end

  def update?
    user.admin? || user.editor? || assistant.user_id == user.id
  end

  def destroy?
    user.admin?
  end
end
