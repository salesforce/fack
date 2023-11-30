class Library < ApplicationRecord
  has_many :documents
  validates :name, presence: true
  belongs_to :user
end
