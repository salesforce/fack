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
  has_many :comments, dependent: :destroy

  # Recently viewed items feature
  has_many :viewed_items, dependent: :destroy

  # Returns the most recently viewed documents for this user
  # @param limit [Integer] the maximum number of documents to return (default: 5)
  # @return [ActiveRecord::Relation<Document>] the recently viewed documents, ordered by most recent first
  def recently_viewed_documents(limit: 5)
    Document.joins(:viewed_items)
            .where(viewed_items: { user_id: id })
            .order('viewed_items.viewed_at DESC')
            .distinct
            .limit(limit)
  end

  # Returns the most recently viewed libraries for this user
  # @param limit [Integer] the maximum number of libraries to return (default: 5)
  # @return [ActiveRecord::Relation<Library>] the recently viewed libraries, ordered by most recent first
  def recently_viewed_libraries(limit: 5)
    Library.joins(:viewed_items)
           .where(viewed_items: { user_id: id })
           .order('viewed_items.viewed_at DESC')
           .distinct
           .limit(limit)
  end

  # Generic method to get recently viewed items of any type
  # @param viewable_type [String] the type of viewable items to retrieve (e.g., 'Document')
  # @param limit [Integer] the maximum number of items to return (default: 5)
  # @return [ActiveRecord::Relation] the recently viewed items
  def recently_viewed(viewable_type:, limit: 5)
    viewable_type.constantize
                 .joins(:viewed_items)
                 .where(viewed_items: { user_id: id })
                 .order('viewed_items.viewed_at DESC')
                 .distinct
                 .limit(limit)
  end

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
