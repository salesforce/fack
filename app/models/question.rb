class Question < ApplicationRecord
  validates :question, presence: true
  validates :prompt, presence: true
end
