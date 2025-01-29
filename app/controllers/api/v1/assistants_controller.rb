# frozen_string_literal: true

module Api
  module V1
    class AssistantsController < BaseAssistantsController
      skip_before_action :verify_authenticity_token, only: %i[create pdwebhook]

      # This can be configured to receive PD messages from https://salesforce.pagerduty.com/integrations/webhooks/add
      # We can then respond to PD alerts with GenAI responses
      def pdwebhook
        payload = request.body.read
        logger.info "Webhook received for Assistant ID: #{params[:id]}"
        logger.info "Payload: #{payload}"

        @chat = Chat.new
        @chat.user_id = current_user.id

        if assistant = Assistant.find_by(id: params[:id])
          @chat.assistant = assistant
        end

        @chat.first_message = payload
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
