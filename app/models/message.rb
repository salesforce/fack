class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  after_create :enqueue_generate_message_response_job
  validates :from, presence: true
  validates :content, presence: true

  enum from: { user: 0, assistant: 1 }
  enum status: { ready: 0, generating: 1 }

  private

  def enqueue_generate_message_response_job
    return unless user?

    GenerateMessageResponseJob.set(priority: 1).perform_later(id)
  end
end
