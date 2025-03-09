require 'json'
require 'openssl'

class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token # Slack requests don’t include CSRF tokens
  skip_before_action :require_login

  before_action :verify_slack_signature

  def events
    payload = JSON.parse(request.body.read)

    # Handle Slack's URL verification challenge
    if payload['type'] == 'url_verification'
      render json: { challenge: payload['challenge'] }
      return
    end

    handle_message_event(payload['event']) if payload['event'] && payload['event']['type'] == 'app_mention'

    head :ok
  end

  private

  # Verifies that the request is really from Slack using the Signing Secret
  def verify_slack_signature
    slack_signature = request.headers['X-Slack-Signature']
    slack_timestamp = request.headers['X-Slack-Request-Timestamp']

    if (Time.now.to_i - slack_timestamp.to_i).abs > 60 * 5
      render json: { error: 'Request too old' }, status: :unauthorized
      return
    end

    sig_basestring = "v0:#{slack_timestamp}:#{request.raw_post}"
    computed_signature = 'v0=' + OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new('sha256'),
      ENV.fetch('SLACK_SIGNING_SECRET', nil),
      sig_basestring
    )

    return if ActiveSupport::SecurityUtils.secure_compare(computed_signature, slack_signature)

    render json: { error: 'Invalid signature' }, status: :unauthorized
  end

  def handle_message_event(event)
    user = event['user']
    text = event['text']
    channel = event['channel']
    parent_user_id = event['parent_user_id']
    thread_ts = event['thread_ts'] || event['ts'] # Use `thread_ts` if it's part of a thread, else use `ts`

    # Get bot's user ID
    slack_service = SlackService.new
    bot_user_id = slack_service.bot_id

    # Check if channel is blank
    if channel.blank?
      Rails.logger.error 'Received event with blank channel'
      return
    end

    # Ignore messages from the bot itself
    return if user == bot_user_id || event['bot_id'] # Skip bot messages

    # Step 1: Find the assistant based on the channel name
    assistant = Assistant.find_by(slack_channel_name: channel)

    unless assistant
      Rails.logger.error "No assistant found for channel: #{channel}"
      return
    end

    # Disable reply to non-bot created threads. Eventually we should enable @fack for other threads
    return if parent_user_id != bot_user_id && assistant.disable_nonbot_chat

    # Step 2: Find an existing chat by thread_ts, or create a new one
    chat = Chat.find_by(slack_thread: thread_ts)

    text = text&.gsub(/<@U[A-Z0-9]+>/, '')&.strip # Removes Slack mentions safely

    if chat.nil?
      chat = Chat.new(
        user_id: User.first.id,
        assistant:,
        first_message: text,
        slack_thread: thread_ts
      )
      chat.save!

      # Post an emoji
      SlackService.new.add_reaction(channel:, timestamp: thread_ts, emoji: 'star')
    end

    # Step 3: Store the message in the chat
    chat.messages.create!(content: text, user_id: chat.user_id, from: 'user')
  end
end
