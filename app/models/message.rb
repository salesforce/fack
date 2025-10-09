class Message < ApplicationRecord
  belongs_to :chat
  belongs_to :user
  after_create :enqueue_generate_message_response_job
  after_save :create_slack_post
  validates :from, presence: true
  validates :content, presence: true

  enum :from, { user: 0, assistant: 1 }
  enum :status, { ready: 0, generating: 1 }

  after_commit :broadcast_message, on: %i[create update]

  private

  def create_slack_post
    return unless should_post_to_slack?

    begin
      post_message_to_slack
      add_pagerduty_reaction_if_needed
    rescue StandardError => e
      handle_slack_error(e)
    end
  end

  def should_post_to_slack?
    return false if slack_channel_id.blank?
    return false unless ready?
    return false if slack_ts.present?
    return false if assistant_reply_only_mode_violated?

    true
  end

  def slack_channel_id
    @slack_channel_id ||= chat.assistant.slack_channel_name.presence || chat.slack_channel_id
  end

  def assistant_reply_only_mode_violated?
    # If assistant is set to reply only and this is an assistant message without an existing thread,
    # it means we're trying to start a new conversation which violates reply-only mode
    chat.assistant.slack_reply_only? && assistant? && chat.slack_thread.blank?
  end

  def post_message_to_slack
    slack_service = SlackService.new
    self.slack_ts = slack_service.post_message(slack_channel_id, content, chat.slack_thread, assistant?)

    update_chat_thread_if_needed
    log_error_if_post_failed
  end

  def update_chat_thread_if_needed
    return unless chat.slack_thread.nil? && slack_ts.present?

    chat.update!(slack_thread: slack_ts)
  end

  def log_error_if_post_failed
    return if slack_ts.present?

    Rails.logger.error("Failed to create Slack thread for chat ID: #{chat.id}")
  end

  def add_pagerduty_reaction_if_needed
    return unless slack_ts.present?
    return unless chat.webhook&.hook_type == 'pagerduty'

    SlackService.new.add_reaction(
      channel: chat.assistant.slack_channel_name,
      timestamp: slack_ts,
      emoji: 'pagerduty'
    )
  end

  def handle_slack_error(error)
    Rails.logger.error("Error in create_slack_post for message #{id}: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))

    # Consider using a separate error tracking field instead of modifying content
    error_message = "⚠️ Slack Error: #{error.message}"
    update_column(:content, "#{content}\n\n#{error_message}")
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
