require 'slack-ruby-client'

class SlackService
  class Error < StandardError; end

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

  # Fetch the channel details
  def get_channel_info(channel_id)
    response = @client.conversations_info(channel: channel_id)
    if response['ok']
      response['channel']
    else
      Rails.logger.error("[Slack Error] Failed to fetch channel info for #{channel_id}: #{response['error']}")
      nil
    end
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("[Slack Error] Failed to fetch channel info for #{channel_id}: #{e.message}")
    nil
  end

  def delete_message(channel, timestamp)
    response = @client.chat_delete(
      channel:,
      ts: timestamp
    )

    raise Error, "Failed to delete message: #{response['error']}" unless response['ok']

    response
  rescue Slack::Web::Api::Errors::SlackError => e
    raise Error, "Slack API error: #{e.message}"
  end

  # Slack has a limit of 3000 characters per message, so we have to chunk
  # Max length constant. Need to leave extra room for tag lines, warnings, etc.
  TEXT_LIMIT = 2500

  def post_message(channel, text, thread_ts = nil, include_button = false)
    return if text.to_s.strip.empty?

    # Function to split text into chunks under the TEXT_LIMIT, breaking at newlines when possible
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

      next if chunk.empty?

      # convert chunk to slack markdown

      payload[:blocks] = [
        {
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: convert_to_slack_markdown(chunk)
          }
        }
      ]

      begin
        if index == 0 && thread_ts.nil?
          response = @client.chat_postMessage(payload)
          thread_ts = response&.ts # Store the ts for threading
          Rails.logger.info("First message sent. New thread created with thread_ts: #{thread_ts}")
        else
          payload[:thread_ts] = thread_ts
          response = @client.chat_postMessage(payload)
          Rails.logger.info("Threaded message sent under thread_ts: #{thread_ts}")
        end
      rescue Slack::Web::Api::Errors::SlackError => e
        Rails.logger.error("[Slack Error] #{e.message}")
      end
    end

    if include_button
      payload_action = {
        channel:,
        as_user: true,
        blocks: [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: '*Will this :point_up: answer help others in the future?* Remembering the answer will improve the AI responses in the future!'
            }
          },
          {
            type: 'actions',
            elements: [
              {
                type: 'button',
                style: 'primary',
                text: {
                  type: 'plain_text',
                  text: ':heart: Remember This'
                },
                value: 'save_document',
                action_id: 'save_document_action'
              }
            ]
          }
        ]
      }

      payload_action[:thread_ts] = thread_ts

      response = @client.chat_postMessage(payload_action)
    end

    thread_ts
  end

  def convert_to_slack_markdown(text)
    return '' if text.nil?

    slack_lines = []

    text.to_s.each_line do |line|
      line = line.to_s.chomp

      # Convert [text](link) to Slack's <link|text> format
      line = line.gsub(/\[([^\]]+)\]\(([^)]+)\)/) do
        "<#{::Regexp.last_match(2)}|#{::Regexp.last_match(1)}>"
      end

      slack_lines << case line
                     when /^#+\s+(.+)$/ # Any number of hashes for header
                       match = ::Regexp.last_match(1)
                       "=*#{match ? match.strip : ''}*="
                     when /^(\d+\.)\s\*\*(.+?)\*\*:(.*)$/ # Numbered item with bold title
                       num = ::Regexp.last_match(1)
                       title = ::Regexp.last_match(2)&.strip || ''
                       content = ::Regexp.last_match(3)&.strip || ''
                       "#{num} *#{title}*:#{content}"
                     when /^\s+-\s(.+)$/ # Sub-bullet
                       content = ::Regexp.last_match(1)&.strip || ''
                       "     • #{content}"
                     when /^(\d+\.)\s\[(.+?)\]\((.+?)\)/ # Numbered list of links
                       line
                     when /^\s+-\s\*\*(.+?)\*\*:(.*)$/ # Indented key-value with bold key
                       key = ::Regexp.last_match(1)&.strip || ''
                       value = ::Regexp.last_match(2)&.strip || ''
                       "     *#{key}*: #{value}"
                     when /^\s+-\s(.+?):\s(.+)$/ # Indented key-value
                       key = ::Regexp.last_match(1)&.strip || ''
                       value = ::Regexp.last_match(2)&.strip || ''
                       "     *#{key}*: #{value}"
                     when /^\*\*(.+?)\*\*$/ # Standalone bolded item
                       content = ::Regexp.last_match(1)&.strip || ''
                       "*#{content}*"
                     when /^-+\s*(.+)$/ # Generic dash list item
                       content = ::Regexp.last_match(1)&.strip || ''
                       "*•* #{content}"
                     when /^(\d+\.)\s(.+)$/ # Numbered item
                       num = ::Regexp.last_match(1)
                       content = ::Regexp.last_match(2)&.strip || ''
                       "#{num} #{content}"
                     else
                       line.to_s
                     end
    end

    slack_lines.join("\n")
  end
end
