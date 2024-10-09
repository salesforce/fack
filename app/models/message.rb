class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  after_create :enqueue_generate_message_response_job
  validates :from, presence: true
  validates :content, presence: true

  enum from: { user: 0, assistant: 1 }
  enum status: { ready: 0, generating: 1 }

  after_commit :broadcast_message, on: %i[create update]

  private

  def enqueue_generate_message_response_job
    return unless user?

    GenerateMessageResponseJob.set(priority: 1).perform_later(id)
  end

  def broadcast_message
    # This will broadcast the message to the 'messages_channel' after the message is saved
    puts 'SENDING from model'
    ActionCable.server.broadcast('messages_channel', { message: self })
  end
end
