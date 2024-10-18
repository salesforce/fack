# frozen_string_literal: true

class LibraryPolicy < ApplicationPolicy
  attr_reader :user, :library

  def initialize(user, library)
    @user = user
    @library = library
  end

  # Only global admins can create libraries
  def create?
    user.admin?
  end

  # Admins and library owners/editors can modify the library
  def update?
    user.admin? || user_is_editor? || user_is_owner?
  end

  private

  def user_is_owner?
    @user.id == @library.user_id
  end

  def user_is_editor?
    library_user = LibraryUser.find_by(user:, library:)
    library_user&.editor? || library_user&.admin?
  end
end
