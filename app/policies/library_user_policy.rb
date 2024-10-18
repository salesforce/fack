# frozen_string_literal: true

class LibraryUserPolicy < ApplicationPolicy
  attr_reader :user, :library_user

  def initialize(user, library_user)
    @user = user
    @library_user = library_user
  end

  # Allow library owner to update other users on the library
  def create?
    user.admin? || user.editor? || @library_user.library.user_id == @user.id
  end

  def destroy?
    create?
  end

  def update?
    false
  end
end
