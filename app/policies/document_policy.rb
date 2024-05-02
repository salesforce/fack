# frozen_string_literal: true

class DocumentPolicy < ApplicationPolicy
  attr_reader :user, :document

  def initialize(user, document)
    @user = user
    @document = document
  end

  def create?
    user.admin? || document.library.user_id == user.id
  end

  def update?
    user.admin? || document.library.user_id == user.id
  end
end
