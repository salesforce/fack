class Question < ApplicationRecord
  validates :question, presence: true
  validates :prompt, presence: true
  belongs_to :user, optional: true

  before_save :check_unable_to_answer

  private

  def check_unable_to_answer
    return unless answer&.include?('I am unable')

    self.able_to_answer = false
  end
end
