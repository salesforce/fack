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

    handle_message_event(payload['event']) if payload['event'] && payload['event']['type'] == 'message'

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

    # Example: log or process the reply
    Rails.logger.info "User #{user} said: #{text} in channel #{channel}"

    # Optionally, you can respond back to the user
    Slack::Web::Client.new.chat_postMessage(
      channel:,
      text: "Thanks for your reply, <@#{user}>! We received: '#{text}'"
    )
  end
end
