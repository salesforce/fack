class Comment < ApplicationRecord
  belongs_to :document
  belongs_to :user

  validates :content, presence: true, length: { minimum: 1, maximum: 2000 }
  validates :document, presence: true
  validates :user, presence: true

  scope :ordered, -> { order(created_at: :desc) }
end
