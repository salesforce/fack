require 'json'
require 'openssl'

class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token # Slack requests don’t include CSRF tokens
  skip_before_action :require_login

  before_action :verify_slack_signature

  SAVE_DOCUMENT_ACTION_ID = 'save_document_action'
  def interactivity
    request_body = begin
      request.body.read
    rescue IOError => e
      Rails.logger.error("[Slack Interactivity] Failed to read request body: #{e.message}")
      return head :bad_request
    end

    begin
      action = extract_action_details(request_body)
      message = extract_message(request_body)

      thread_ts = message['thread_ts']
      message_ts = message['ts']
      unless thread_ts
        Rails.logger.error("[Slack Interactivity] Missing thread_ts in message: #{message.inspect}")
        return head :unprocessable_entity
      end

      if action['action_id'] == SAVE_DOCUMENT_ACTION_ID
        chat = Chat.find_by_slack_thread(thread_ts)
        unless chat
          Rails.logger.error("[Slack Interactivity] Chat not found for thread_ts: #{thread_ts}")
          return head :not_found
        end

        doc_text = chat.messages.where(from: 'assistant').last&.content
        unless doc_text
          Rails.logger.error("[Slack Interactivity] No assistant message found for thread_ts: #{thread_ts}")
          return head :unprocessable_entity
        end

        title = chat.first_message&.truncate(100) || "Untitled Document (#{thread_ts})"

        new_doc = Document.new(
          document: doc_text,
          title:,
          user_id: chat.user_id,
          library_id: chat.assistant.library_id
        )

        slack_service = SlackService.new
        channel = chat.assistant.slack_channel_name

        if new_doc.save
          document_url = "#{ENV.fetch('ROOT_URL', 'http://localhost')}/#{document_path(new_doc)}"

          # Post confirmation message
          confirmation_ts = nil
          begin
            response = slack_service.post_message(
              channel,
              "✨ Saved document! #{document_url}",
              chat.slack_thread
            )
            confirmation_ts = response['ts'] if response['ok']
          rescue SlackService::Error => e
            Rails.logger.error("[Slack Interactivity] Failed to post confirmation: #{e.message}")
          end

          # Delete the original message
          begin
            slack_service.delete_message(channel, message_ts)
          rescue SlackService::Error => e
            Rails.logger.error("[Slack Interactivity] Failed to delete original message: #{e.message}")
            # Optionally post an error message if deletion fails
            if confirmation_ts.nil?
              slack_service.post_message(
                channel,
                "Document saved but couldn't clean up original message: #{e.message}",
                chat.slack_thread
              )
            end
          end
        else
          Rails.logger.error("[Slack Interactivity] Failed to save document: #{new_doc.errors.full_messages.join(', ')}")
          slack_service.post_message(
            channel,
            "❌ Failed to save document: #{new_doc.errors.full_messages.join(', ')}",
            chat.slack_thread
          )
          return head :unprocessable_entity
        end
      else
        Rails.logger.warn("[Slack Interactivity] Unhandled action_id: #{action['action_id']}")
        return head :unprocessable_entity
      end
    rescue JSON::ParserError => e
      Rails.logger.error("[Slack Interactivity] Failed to parse request body: #{e.message}\n#{e.backtrace.join("\n")}")
      return head :bad_request
    rescue NoMethodError => e
      Rails.logger.error("[Slack Interactivity] Unexpected data structure: #{e.message}\n#{e.backtrace.join("\n")}")
      return head :unprocessable_entity
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("[Slack Interactivity] Record not found: #{e.message}")
      return head :not_found
    rescue StandardError => e
      Rails.logger.error("[Slack Interactivity] Unexpected error: #{e.message}\n#{e.backtrace.join("\n")}")
      return head :internal_server_error
    end

    head :ok
  end

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

  def extract_message(payload)
    # Decode the URL-encoded payload
    decoded_payload = URI.decode_www_form(payload).to_h['payload']

    # Parse the JSON payload
    parsed_payload = JSON.parse(decoded_payload)

    # Extract the message text
    parsed_payload.dig('message')
  end

  def extract_action_details(payload)
    # Parse the JSON payload (assuming it's a JSON string)
    decoded_payload = URI.decode_www_form(payload).to_h['payload']

    # Parse the JSON payload
    parsed_payload = JSON.parse(decoded_payload)

    # Extract actions array
    actions = parsed_payload.dig('actions')

    # Return nil if no actions found
    return nil if actions.nil? || actions.empty?

    # Extract first action (assuming only one action is clicked at a time)
    actions.first
  end

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
    message_ts = event['ts']
    thread_ts = event['thread_ts'] || event['ts'] # Use `thread_ts` if it's part of a thread, else use `ts`

    # Get bot's user ID
    slack_service = SlackService.new
    bot_user_id = slack_service.bot_id

    SlackService.new.add_reaction(channel:, timestamp: message_ts, emoji: 'writing_hand')

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
    end

    chat.messages.create!(content: text, user_id: chat.user_id, from: 'user')
  end
end
