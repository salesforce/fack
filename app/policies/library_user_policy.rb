# frozen_string_literal: true

class LibraryUserPolicy < ApplicationPolicy
  attr_reader :user, :library_user

  def initialize(user, library_user)
    @user = user
    @library_user = library_user
  end

  def create?
    user.admin?
  end

  def update?
    false
  end
end
