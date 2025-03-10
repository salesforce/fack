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

  # Max length constant.  Need to leave extra room for tag lines, warnings, etc.
  TEXT_LIMIT = 2500
  def post_message(channel, text, thread_ts = nil)
    return if text.to_s.strip.empty?

    # Function to split text into chunks under the TEXT_LIMIT, breaking at newlines when possible
    # Slack has a limit of about 3000 characters per post section
    # So we are breaking up long responses into chunks which fit into the slack limit.
    def split_text(text, limit)
      chunks = []
      while text.length > limit
        split_index = text.rindex("\n", limit) || text.rindex(' ', limit) || limit
        chunks << text[0...split_index].strip
        text = text[split_index..].strip
      end
      chunks << text unless text.empty?
      chunks
    end

    body_chunks = split_text(text, TEXT_LIMIT)

    body_chunks.each_with_index do |chunk, index|
      payload = {
        channel:,
        as_user: true,
        text: chunk
      }

      # Only add blocks if there's a body
      next if chunk.empty?

      payload[:blocks] = [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: chunk
          }
        }
      ]
      begin
        if index == 0 && thread_ts.nil?
          # First message, and no existing thread_ts, so create a new thread
          response = @client.chat_postMessage(payload)
          thread_ts = response&.ts # Store the ts for threading
          Rails.logger.info("First message sent. New thread created with thread_ts: #{thread_ts}")
        else
          # Use existing thread_ts for threading
          payload[:thread_ts] = thread_ts
          response = @client.chat_postMessage(payload)
          Rails.logger.info("Threaded message sent under thread_ts: #{thread_ts}")
        end
      rescue Slack::Web::Api::Errors::SlackError => e
        Rails.logger.error("[Slack Error] #{e.message}")
      end
    end
    thread_ts
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
