require 'slack-ruby-client'

class SlackService
  def initialize
    Slack.configure do |config|
      config.token = ENV.fetch('SLACK_BOT_TOKEN', nil)
    end

    @client = Slack::Web::Client.new
  end

  # Post a message to a Slack channel
  def post_message(channel, text)
    @client.chat_postMessage(
      channel:,
      text:,
      as_user: true
    )
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

  # Fetch recent threads in a Slack channel from the last X minutes
  def fetch_recent_threads(channel, minutes)
    messages = fetch_recent_messages(channel, minutes)

    threads = messages
              .select { |msg| msg['thread_ts'] } # Filter messages that started threads
              .map { |msg| fetch_thread_replies(channel, msg['thread_ts']) }

    threads.flatten
  end
end
