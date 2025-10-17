# frozen_string_literal: true

class ViewedItem < ApplicationRecord
  belongs_to :user
  belongs_to :viewable, polymorphic: true

  validates :user_id, presence: true
  validates :viewable_id, presence: true
  validates :viewable_type, presence: true
  validates :viewed_at, presence: true

  # Ensure uniqueness at the model level as well
  validates :user_id, uniqueness: { scope: %i[viewable_type viewable_id] }

  # Scope to get most recently viewed items
  scope :recent, -> { order(viewed_at: :desc) }

  # Scope to get items for a specific viewable type
  scope :for_type, ->(type) { where(viewable_type: type) }
end
