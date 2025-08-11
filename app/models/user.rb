# frozen_string_literal: true

class User < ApplicationRecord
  acts_as_voter

  has_one :google_authorization

  has_secure_password validations: false
  validate :password_strength

  has_many :library_users
  has_many :libraries, through: :library_users
  has_many :owned_libraries, class_name: 'Library', foreign_key: 'user_id'
  has_many :owned_assistants, class_name: 'Assistant', foreign_key: 'user_id'

  has_many :assistant_users
  has_many :assistants, through: :assistant_users

  private

  def password_strength
    return if password.blank?

    # Check for minimum length
    min_length = 8
    if password.length < min_length
      errors.add(:password,
                 "must be at least #{min_length} characters long")
    end

    # Check for at least one uppercase letter
    errors.add(:password, 'must contain at least one uppercase letter') unless password =~ /[A-Z]/

    # Check for at least one lowercase letter
    errors.add(:password, 'must contain at least one lowercase letter') unless password =~ /[a-z]/

    # Check for at least one digit
    errors.add(:password, 'must contain at least one digit') unless password =~ /\d/

    # Check for at least one special character
    special_characters = "!@\#$%^&*()-+"
    return if password =~ /[#{Regexp.escape(special_characters)}]/

    errors.add(:password, "must contain at least one special character (#{special_characters})")
  end
end
