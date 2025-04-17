require 'json'
require 'openssl'

class SlackController < ApplicationController
  skip_before_action :verify_authenticity_token # Slack requests don't include CSRF tokens
  skip_before_action :require_login

  before_action :verify_slack_signature

  SAVE_DOCUMENT_ACTION_ID = 'save_document_action'
  # Handles Slack interactive components (buttons, menus, etc.)
  # This endpoint processes actions triggered by users in Slack messages
  def interactivity
    # Read the raw request body which contains the Slack payload
    request_body = begin
      request.body.read
    rescue IOError => e
      Rails.logger.error("[Slack Interactivity] Failed to read request body: #{e.message}")
      return head :bad_request
    end

    begin
      # Extract action details (button clicks, menu selections) and message context
      action = extract_action_details(request_body)
      message = extract_message(request_body)

      # Get thread and message timestamps for context
      thread_ts = message['thread_ts']
      message_ts = message['ts']
      unless thread_ts
        Rails.logger.error("[Slack Interactivity] Missing thread_ts in message: #{message.inspect}")
        return head :unprocessable_entity
      end

      # Handle the "Save Document" action
      if action['action_id'] == SAVE_DOCUMENT_ACTION_ID
        # Find the chat associated with this Slack thread
        chat = Chat.find_by_slack_thread(thread_ts)
        unless chat
          Rails.logger.error("[Slack Interactivity] Chat not found for thread_ts: #{thread_ts}")
          return head :not_found
        end

        # Find the most recent assistant message before the current message timestamp
        doc_text = chat.messages.where(from: 'assistant').where('EXTRACT(EPOCH FROM created_at) < ?', message_ts.split('.')[0]).order(created_at: :desc).first&.content
        unless doc_text
          Rails.logger.error("[Slack Interactivity] No assistant message found for thread_ts: #{thread_ts}")
          return head :unprocessable_entity
        end

        # Create a title from the document text or use a default
        title = doc_text&.truncate(100) || "Untitled Document (#{thread_ts})"

        # Create a new document with the extracted content
        new_doc = Document.new(
          document: doc_text,
          title:,
          user_id: chat.user_id,
          library_id: chat.assistant.library_id
        )

        # Initialize Slack service for posting messages
        slack_service = SlackService.new
        channel = chat.slack_channel_id.presence || chat.assistant.slack_channel_name.presence
        unless channel
          Rails.logger.error("[Slack Interactivity] No channel found for chat. First 10 chars of content: '#{chat.first_message&.truncate(10)}'")
          return head :unprocessable_entity
        end

        if new_doc.save
          # Generate the document URL for the confirmation message
          document_url = "#{ENV.fetch('ROOT_URL', 'http://localhost')}/#{document_path(new_doc)}"

          # Post a confirmation message in the Slack thread
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

          # Delete the original message that triggered the save action
          begin
            slack_service.delete_message(channel, message_ts)
          rescue SlackService::Error => e
            Rails.logger.error("[Slack Interactivity] Failed to delete original message: #{e.message}")
            # If deletion fails and we haven't posted a confirmation, post an error message
            if confirmation_ts.nil?
              slack_service.post_message(
                channel,
                "Document saved but couldn't clean up original message: #{e.message}",
                chat.slack_thread
              )
            end
          end
        else
          # Handle document save failure
          error_message = "❌ Failed to save document: #{new_doc.errors.full_messages.join(', ')}"
          Rails.logger.error("[Slack Interactivity] #{error_message}")
          Rails.logger.info(channel + ' ' + chat.slack_thread)
          slack_service.post_message(
            channel,
            error_message,
            chat.slack_thread
          )
          return head :unprocessable_entity
        end
      else
        # Log unhandled action types
        Rails.logger.warn("[Slack Interactivity] Unhandled action_id: #{action['action_id']}")
        return head :unprocessable_entity
      end
    rescue JSON::ParserError => e
      # Handle JSON parsing errors
      Rails.logger.error("[Slack Interactivity] Failed to parse request body: #{e.message}\n#{e.backtrace.join("\n")}")
      return head :bad_request
    rescue NoMethodError => e
      # Handle missing data structure errors
      Rails.logger.error("[Slack Interactivity] Unexpected data structure: #{e.message}\n#{e.backtrace.join("\n")}")
      return head :unprocessable_entity
    rescue ActiveRecord::RecordNotFound => e
      # Handle missing record errors
      Rails.logger.error("[Slack Interactivity] Record not found: #{e.message}")
      return head :not_found
    rescue StandardError => e
      # Handle any other unexpected errors
      Rails.logger.error("[Slack Interactivity] Unexpected error: #{e.message}\n#{e.backtrace.join("\n")}")
      return head :internal_server_error
    end

    # Return success if everything completed without errors
    head :ok
  end

  def events
    payload = JSON.parse(request.body.read)

    # Handle Slack's URL verification challenge
    if payload['type'] == 'url_verification'
      render json: { challenge: payload['challenge'] }
      return
    end

    handle_message_event(payload['event']) if payload['event'] && (payload['event']['type'] == 'app_mention' || payload['event']['type'] == 'member_joined_channel')

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

  # Example member_joined_channel
  # "event": {
  #  "type": "member_joined_channel",
  #  "user": "U08C1FK0BML",
  #  "channel": "C08M923HVTP",
  #  "channel_type": "C",
  #  "team": "T04SR5XV56X",
  #  "inviter": "U05LRAGN1PG",
  #  "enterprise": "E04SQG1CF60",
  #  "event_ts": "1744138889.000200"
  # },

  def handle_message_event(event)
    user = event['user']
    type = event['type']
    text = event['text']
    channel = event['channel']
    parent_user_id = event['parent_user_id']
    message_ts = event['ts'] || event['thread_ts']
    thread_ts = event['thread_ts'] || event['ts'] # Use `thread_ts` if it's part of a thread, else use `ts`

    # Get bot's user ID
    slack_service = SlackService.new
    bot_user_id = slack_service.bot_id

    # Check if channel is blank
    if channel.blank?
      Rails.logger.error 'Received event with blank channel'
      return
    end

    # Find the assistant based on the channel name
    assistant = Assistant.find_by(slack_channel_name: channel)

    # if we don't find the assistant by id, we fall back to the name starts with
    unless assistant
      @channel_info = slack_service.get_channel_info(channel)
      channel_name = @channel_info['name']

      assistant = Assistant.where.not(slack_channel_name_starts_with: [nil, '']).find do |a|
        a.slack_channel_name_starts_with.present? &&
          channel_name.present? &&
          channel_name.start_with?(a.slack_channel_name_starts_with)
      end

      if assistant
        # Found an assistant whose prefix matches
        Rails.logger.info "Found matching assistant: #{assistant.inspect}"
      else
        Rails.logger.info 'No matching assistant found.'
      end
    end

    # If there is no matching assistant, we stop
    unless assistant
      Rails.logger.error "No assistant found for channel: #{channel}"
      return
    end

    if type == 'member_joined_channel' && assistant.enable_channel_join_message
      # Check if there are any existing chats with this channel ID
      existing_chat = Chat.find_by(slack_channel_id: channel)
      # Only create a new chat if there is no existing chat to prevent duplicates
      if existing_chat
        Rails.logger.info("Skipping join event - chat already exists for channel: #{channel}")
        return
      end

      Rails.logger.info('Joined Channel: ' + channel)
      @channel_info ||= slack_service.get_channel_info(channel)

      topic = @channel_info['topic']['value']

      message_text = 'Topic: ' + topic

      chat = Chat.new(
        user_id: assistant.user_id,
        assistant:,
        first_message: message_text,
        slack_channel_id: channel
      )
      chat.save!

      chat.messages.create!(content: message_text, user_id: chat.user_id, from: 'user')
    else
      # Ignore messages from the bot itself
      return if user == bot_user_id || event['bot_id'] # Skip bot messages

      # Disable reply to non-bot created threads. Eventually we should enable @fack for other threads
      return if parent_user_id != bot_user_id && assistant.disable_nonbot_chat

      # Step 2: Find an existing chat by thread_ts, or create a new one
      chat = Chat.find_by(slack_thread: thread_ts)

      text = text&.gsub(/<@U[A-Z0-9]+>/, '')&.strip # Removes Slack mentions safely

      if text.blank?
        Rails.logger.error('Text cannot be blank.')
        return
      end

      if chat.nil?
        chat = Chat.new(
          user_id: assistant.user_id,
          assistant:,
          first_message: text,
          slack_thread: thread_ts,
          slack_channel_id: channel
        )
        chat.save!
      end

      chat.messages.create!(content: text, user_id: chat.user_id, from: 'user', slack_ts: thread_ts)

      SlackService.new.add_reaction(channel:, timestamp: message_ts, emoji: 'writing_hand')
    end
  end
end
