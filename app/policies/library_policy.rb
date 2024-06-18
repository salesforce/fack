# frozen_string_literal: true

class LibraryPolicy < ApplicationPolicy
  attr_reader :user, :library

  def initialize(user, library)
    @user = user
    @library = library
  end

  def create?
    user.admin?
  end

  def update?
    user.admin? || user_is_editor? || library.user_id == user.id
  end

  private

  def user_is_editor?
    library_user = LibraryUser.find_by(user: user, library: library)
    library_user&.editor? || library_user&.admin?
  end
end
