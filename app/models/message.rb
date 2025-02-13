class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  after_create :enqueue_generate_message_response_job
  after_create :create_slack_thread
  validates :from, presence: true
  validates :content, presence: true

  enum from: { user: 0, assistant: 1 }
  enum status: { ready: 0, generating: 1 }

  after_commit :broadcast_message, on: %i[create update]

  private

  def create_slack_thread
    return if chat.slack_thread.present? || chat.assistant.slack_channel_name.blank?

    response = SlackService.new.post_message(chat.assistant.slack_channel_name, content)

    if (ts = response&.dig('ts')) # Safely retrieve the thread timestamp
      chat.update(slack_thread: ts) # One-liner update instead of separate assignment + save
    else
      Rails.logger.error("Failed to create Slack thread for chat ID: #{chat.id}")
    end
  end

  def enqueue_generate_message_response_job
    return unless user?

    GenerateMessageResponseJob.set(priority: 1).perform_later(id)
  end

  def broadcast_message
    # This will broadcast the message to the 'messages_channel' after the message is saved
    ActionCable.server.broadcast('messages_channel', { message: self })
  end
end
