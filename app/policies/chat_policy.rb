# frozen_string_literal: true

class ChatPolicy < ApplicationPolicy
  attr_reader :user, :chat

  def initialize(user, chat)
    @user = user
    @chat = chat
  end

  def destroy?
    user.admin? || chat.user_id == user.id
  end
end
