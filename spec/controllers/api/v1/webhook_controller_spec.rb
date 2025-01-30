require 'rails_helper'

RSpec.describe Api::V1::WebhooksController, type: :controller do
  describe 'POST #receive' do
    let(:payload) do
      {
        event: {
          id: '01FEW58JJ3A39M88ZUXISESOY8',
          event_type: 'incident.annotated',
          resource_type: 'incident',
          occurred_at: '2025-01-30T20:03:42.196Z',
          agent: {
            html_url: 'https://salesforce.pagerduty.com/users/PKJXBVE',
            id: 'PKJXBVE',
            self: 'https://api.pagerduty.com/users/PKJXBVE',
            summary: 'Vijay Swamidass',
            type: 'user_reference'
          },
          client: {},
          data: {
            incident: {
              html_url: 'https://salesforce.pagerduty.com/incidents/Q2L14QSCMS21O0',
              id: 'Q2L14QSCMS21O0',
              self: 'https://api.pagerduty.com/incidents/Q2L14QSCMS21O0',
              summary: 'Argus is down (TEST)',
              type: 'incident_reference'
            },
            id: 'PEUPADO',
            content: "This is a test.",
            trimmed: false,
            type: 'incident_note'
          }
        }
      }.to_json
    end

    let(:user) { create(:user) }
    let(:assistant) { create(:assistant, name: 'genai_assistant', user:) }
    let(:webhook) { create(:webhook, hook_type: :pagerduty, assistant:) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      request.headers['Content-Type'] = 'application/json'
    end

    context 'when a valid PagerDuty webhook is received' do
      it 'creates a new Chat and Message' do
        post :receive, params: { id: webhook.id }, body: payload, as: :json

        expect(response).to have_http_status(:created)

        chat = Chat.find_by(webhook_external_id: 'Q2L14QSCMS21O0')
        expect(chat).not_to be_nil
        expect(chat.user_id).to eq(user.id)
        expect(chat.assistant).to eq(webhook.assistant)
        expect(chat.first_message).to eq(payload)
        expect(chat.webhook_id).to eq(webhook.id)

        message = chat.messages.first
        expect(message.content).to eq(payload)
        expect(message.user_id).to eq(user.id)
        expect(message.from.to_sym).to eq(:user)
      end
    end

    context 'when an invalid webhook is received' do
      it 'does not create a new Chat or Message' do
        invalid_payload = {
          event: {
            resource_type: 'service' # Not an 'incident'
          }
        }.to_json

        post :receive, params: { id: webhook.id }, body: invalid_payload

        expect(response).to have_http_status(:no_content)
        expect(Chat.count).to eq(0)
      end
    end
  end
end
