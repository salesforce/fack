# frozen_string_literal: true

class CliAuthPolicy < ApplicationPolicy
  # Anyone who is authenticated can authorize CLI access
  def new?
    user.present?
  end

  def create?
    user.present?
  end
end
