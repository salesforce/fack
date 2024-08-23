class Message < ApplicationRecord
  belongs_to :chat
  after_create :enqueue_generate_message_response_job

  enum from: { user: 0, assistant: 1 }

  private

  def enqueue_generate_message_response_job
    return unless user?

    GenerateMessageResponseJob.set(priority: 1).perform_later(id)
  end
end
