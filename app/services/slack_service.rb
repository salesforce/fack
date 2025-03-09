require 'slack-ruby-client'

class SlackService
  def initialize
    Slack.configure do |config|
      config.token = ENV.fetch('SLACK_BOT_TOKEN', nil)
    end

    @client = Slack::Web::Client.new
  end

  # Fetch the bot's user ID
  def bot_id
    @bot_id ||= @client.auth_test['user_id']
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("[Slack Error] Failed to fetch bot ID: #{e.message}")
    nil
  end

  def add_reaction(channel:, timestamp:, emoji:)
    unless channel && timestamp && emoji
      Rails.logger.error("[Slack Error] Missing arguments for add_reaction: channel=#{channel}, ts=#{timestamp}, emoji=#{emoji}")
      return
    end

    @client.reactions_add(
      channel:,
      timestamp:,
      name: emoji
    )
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("[Slack Error] Failed to add reaction: #{e.message}")
  end

  # Max length constants.  Need to leave extra room for tag lines, warnings, etc.
  TEXT_LIMIT = 3500
  BLOCKS_LIMIT = 2500

  # Post a message to a Slack channel or a thread
  def post_message(channel, text, thread_ts = nil)
    # Ensure text is within Slack limits
    truncated_text = text.length > TEXT_LIMIT ? text[0...TEXT_LIMIT] + '...' : text
    truncated_blocks_text = text.length > BLOCKS_LIMIT ? text[0...BLOCKS_LIMIT] + '...' : text

    payload = {
      channel:,
      as_user: true,
      text: truncated_text # Ensure fallback text does not exceed 4000 chars
    }

    # Only add blocks if text is not empty
    unless text.to_s.strip.empty?
      payload[:blocks] = [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: truncated_blocks_text # Ensure block text does not exceed 3000 chars
          }
        }
      ]
    end

    payload[:thread_ts] = thread_ts if thread_ts.to_s.strip != ''

    @client.chat_postMessage(payload)
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("[Slack Error] #{e.message}")
  end

  # Fetch messages from the last X minutes in a channel
  def fetch_recent_messages(channel, minutes)
    oldest = (Time.now - (minutes * 60)).to_i.to_s
    response = @client.conversations_history(channel:, oldest:)

    response['messages']
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("[Slack Error] #{e.message}")
    []
  end

  # Fetch thread replies for a given thread timestamp
  def fetch_thread_replies(channel, thread_ts)
    response = @client.conversations_replies(channel:, ts: thread_ts)
    response['messages']
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("[Slack Error] #{e.message}")
    []
  end

  def fetch_recent_threads(channel, minutes)
    messages = fetch_recent_messages(channel, minutes)

    # Separate thread starters and standalone messages
    thread_starters = messages.select { |msg| msg['thread_ts'] }
    standalone_messages = messages.reject { |msg| msg['thread_ts'] } # Standalone messages (no replies)

    # Fetch all replies for thread starters
    threads_with_replies = thread_starters.map { |msg| fetch_thread_replies(channel, msg['thread_ts']) }

    # Combine standalone messages with full threads
    (standalone_messages + threads_with_replies.flatten)
  end
end
