# frozen_string_literal: true

class ChatPolicy < ApplicationPolicy
  attr_reader :user, :chat

  def initialize(user, chat)
    @user = user
    @chat = chat
  end

  def create?
    true # Users can create chats
  end

  def show?
    true # Users can view chats (may need to restrict this later)
  end

  def update?
    user.admin? || chat.user_id == user.id
  end

  def edit?
    update?
  end

  def destroy?
    user.admin? || chat.user_id == user.id
  end
end
