# frozen_string_literal: true

require 'json'

module Api
  module V1
    class WebhooksController < BaseWebhooksController
      skip_before_action :verify_authenticity_token, only: %i[create receive]
      before_action :set_webhook

      # Overrides the base ApplicationController api auth method
      # We allow the webhoook token to authenticate only on this controller
      def authenticate_api_with_token
        authenticate_with_http_token do |token, _options|
          webhook = Webhook.find_by_secret_key(token)
          if webhook
            login_user(webhook.assistant.user) # May change this to another user later
            return true
          end

          return false
        end
      end

      # This can be configured to receive PD messages from https://salesforce.pagerduty.com/integrations/webhooks/add
      # We can then respond to PD alerts with GenAI responses
      def receive
        # Add check if is PD webhook. Other Types will be handled later.
        return unless @webhook.hook_type == 'pagerduty'

        payload = request.body.read
        logger.info "Webhook received for Webhook ID: #{params[:id]}"

        event = JSON.parse(payload)

        resource_type = event['event']['resource_type']
        return unless resource_type == 'incident'

        # Get the incident ID from the event data. It varies in the payload
        event_type = event['event']['event_type']
        incident_id = event['event']['data']['id']
        incident_url = event['event']['data']['html_url']
        incident_start_time = event['event']['data']['created_at']
        incident_end_time = event['event']['occurred_at']

        unless %w[incident.resolved incident.acknowledged].include?(event_type)
          logger.warn "Unknown event type received: #{event_type}"
          return
        end

        event_text = if event_type == 'incident.resolved'
                       "Incident resolved. Start: #{incident_start_time}, End: #{incident_end_time} \n" \
                         "<#{incident_url}|View Incident>"
                     else
                       "Incident acknowledged: #{event['event']['data']['title']} \n" \
                         "<#{incident_url}|View Incident>"
                     end

        # We want to respond to annotations, but not our own. Otherwise, it will get in an endless loop
        # So we add a tagline to detect when our agent is posting vs. a normal user
        tagline = ENV.fetch('WEBHOOK_TAGLINE', '')
        return if event_type == 'incident.annotated' && tagline && payload.include?(tagline)

        @chat = Chat.find_by(webhook_external_id: incident_id)

        # If it's a resolved event and there's no existing chat, exit early
        return if event_type == 'incident.resolved' && @chat.nil?

        if @chat.nil?
          @chat = Chat.new
          @chat.user_id = current_user.id
          @chat.assistant = @webhook.assistant
          @chat.first_message = event_text
          @chat.webhook_id = @webhook.id
          @chat.webhook_external_id = incident_id
        end

        respond_to do |format|
          if @chat.save
            @chat.messages.create(content: event_text, user_id: @chat.user_id, from: :user)
            format.json { render json: { id: @chat.id }, status: :created }
          else
            format.json { render json: @chat.errors, status: :unprocessable_content }
          end
        end
      end
    end
  end
end
