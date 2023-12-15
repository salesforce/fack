class Question < ApplicationRecord
  has_neighbors :embedding
  
  enum status: { pending: 0, generating: 1, generated: 2, failed: 3 }

  validates :question, presence: true
  belongs_to :user, optional: true

  before_save :check_unable_to_answer

  private

  def check_unable_to_answer
    return unless answer&.include?('I am unable to answer the question')

    self.able_to_answer = false
  end
end
