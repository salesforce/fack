# frozen_string_literal: true

class DocumentPolicy < ApplicationPolicy
  attr_reader :user, :document

  def initialize(user, document)
    @user = user
    @document = document
  end

  def create?
    user.admin? || document.library.user_id == user.id || user_is_editor?
  end

  def update?
    user.admin? || document.library.user_id == user.id || user_is_editor?
  end

  private

  def user_is_editor?
    library_user = LibraryUser.find_by(user: user, library: document.library)
    library_user&.editor? || library_user&.admin?
  end
end
