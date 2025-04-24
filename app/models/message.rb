class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  after_create :enqueue_generate_message_response_job
  after_save :create_slack_post
  validates :from, presence: true
  validates :content, presence: true

  enum from: { user: 0, assistant: 1 }
  enum status: { ready: 0, generating: 1 }

  after_commit :broadcast_message, on: %i[create update]

  private

  def create_slack_post
    channel_id = chat.assistant.slack_channel_name.presence || chat.slack_channel_id

    # Skip if there is already a thread linked or the assistant doesn't have a slack channel
    return if channel_id.blank?

    # If the assistant is generating, then it isn't ready and we don't post to slack
    return unless ready?

    # skip if this message already has a slack ts
    return if slack_ts

    begin
      slack_service = SlackService.new

      # if the chat.slack_thread is missing, we create a new thread
      self.slack_ts = slack_service.post_message(channel_id, content, chat.slack_thread, assistant?)

      # if the chat didn't have a thread, save it.
      if chat.slack_thread.nil?
        chat.slack_thread = slack_ts
        chat.save
      end

      if slack_ts
        slack_service.add_reaction(channel: chat.assistant.slack_channel_name, timestamp: slack_ts, emoji: 'pagerduty') if chat.webhook && (chat.webhook.hook_type == 'pagerduty')
      else
        Rails.logger.error("Failed to create Slack thread for chat ID: #{chat.id}")
      end
    rescue StandardError => e
      Rails.logger.error("Error in create_slack_post for message #{id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      # Update the message content with the error information, bypassing callbacks
      error_message = "⚠️ Slack Error: #{e.message}"

      # There may be a better place to do this, but will look at that later
      update_column(:content, "#{content}\n\n#{error_message}")
      # Don't raise the error to prevent the message creation from failing
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
