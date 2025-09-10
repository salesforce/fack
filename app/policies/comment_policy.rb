# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def update?
    user.present? && (user == record.user || user.admin?)
  end

  def destroy?
    user.present? && (user == record.user || user.admin?)
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
