# frozen_string_literal: true

class AssistantUserPolicy < ApplicationPolicy
  attr_reader :user, :assistant_user

  def initialize(user, assistant_user)
    @user = user
    @assistant_user = assistant_user
  end

  # Allow assistant owner to update other users on the assistant
  def create?
    user.admin? || user.editor? || @assistant_user.assistant.user_id == @user.id
  end

  def destroy?
    create?
  end

  def update?
    false
  end
end
