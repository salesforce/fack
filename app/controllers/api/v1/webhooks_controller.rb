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
        event_text = ''
        incident_id = ''
        if event_type == 'incident.annotated'
          incident_id = event['event']['data']['incident']['id']
          incident_url = event['event']['data']['incident']['html_url']
          incident_summary_text = event['event']['data']['incident']['summary']

          event_text += 'content: ' + event['event']['data']['content']

          # if text contains "Resolution Note:" Then created a doc
          # Get the webhook library and create a doc
          if event_text.include?('Resolution Note:')
            # Create a doc
            doc_text = event['event']['data']['content'] + ' PD URL: ' + incident_url + ' Summary: ' + incident_summary_text
            doc = Document.create(document: doc_text, user_id: current_user.id, library_id: @webhook.library.id)
          end

        else
          incident_id = event['event']['data']['id']
          event_text += 'title: ' + event['event']['data']['title']
        end

        # We want to respond to annotations, but not our own.  Otherwise, it will get in an endless loop
        # So we add a tagline to detect when our agent is posting vs. a normal user
        tagline = ENV.fetch('WEBHOOK_TAGLINE', '')
        return if event_type == 'incident.annotated' && tagline && payload.include?(tagline)

        @chat = Chat.find_by(webhook_external_id: incident_id)
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
