class Question < ApplicationRecord
  validates :question, presence: true
  validates :prompt, presence: true
  belongs_to :user, optional: true
end
