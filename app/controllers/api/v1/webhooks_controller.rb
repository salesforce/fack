# frozen_string_literal: true

require 'json'

module Api
  module V1
    class WebhooksController < BaseWebhooksController
      skip_before_action :verify_authenticity_token, only: %i[create receive]
      before_action :set_webhook

      # This can be configured to receive PD messages from https://salesforce.pagerduty.com/integrations/webhooks/add
      # We can then respond to PD alerts with GenAI responses
      def receive
        # TODO: - add key verification from webhook

        # Add check if is PD webhook.  Other Types will be handled later.
        return unless @webhook.hook_type == 'pagerduty'

        payload = request.body.read
        logger.info "Webhook received for Webhook ID: #{params[:id]}"

        event = JSON.parse(payload)

        resource_type = event['event']['resource_type']
        return unless resource_type == 'incident'

        # Get the incident ID from the event data.  It varies in the payload
        event_type = event['event']['event_type']
        incident_id = if event_type == 'incident.annotated'
                        event['event']['data']['incident']['id']
                      else
                        event['event']['data']['id']
                      end

        tagline = ENV.fetch('WEBHOOK_TAGLINE', '')
        return if event_type == 'incident.annotated' && tagline && payload.include?(tagline)

        @chat = Chat.find_by(webhook_external_id: incident_id)
        if @chat.nil?
          @chat = Chat.new
          @chat.user_id = current_user.id
          @chat.assistant = @webhook.assistant
          @chat.first_message = payload
          @chat.webhook_id = @webhook.id
          @chat.webhook_external_id = incident_id
        end

        respond_to do |format|
          if @chat.save
            @chat.messages.create(content: payload, user_id: @chat.user_id, from: :user)
            format.json { render json: { id: @chat.id }, status: :created }
          else
            format.json { render json: @chat.errors, status: :unprocessable_content }
          end
        end
      end
    end
  end
end
