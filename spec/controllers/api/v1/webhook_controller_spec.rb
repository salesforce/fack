require 'rails_helper'

RSpec.describe Api::V1::WebhooksController, type: :controller do
  describe 'POST #receive' do
    let(:payload_annotate) do
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
              html_url: 'https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ',
              id: 'Q1VVXNR9VO48ZJ',
              self: 'https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ0',
              summary: 'Argus is down (TEST)',
              type: 'incident_reference'
            },
            id: 'PEUPADO',
            content: 'This is a test.',
            trimmed: false,
            type: 'incident_note'
          }
        }
      }.to_json
    end

    let(:payload_ack) do
      {
        event: {
          id: '01FEW8TGIDWE21FOHP5WGIHUSX',
          event_type: 'incident.acknowledged',
          resource_type: 'incident',
          occurred_at: '2025-01-30T20:46:57.114Z',
          agent: {
            html_url: 'https://salesforce.pagerduty.com/users/PKJXBVE',
            id: 'PKJXBVE',
            self: 'https://api.pagerduty.com/users/PKJXBVE',
            summary: 'Vijay Swamidass',
            type: 'user_reference'
          },
          client: nil,
          data: {
            id: 'Q1VVXNR9VO48ZJ',
            type: 'incident',
            self: 'https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ',
            html_url: 'https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ',
            number: 13_541_962,
            status: 'acknowledged',
            incident_key: '[FILTERED]',
            created_at: '2025-01-30T20:46:49Z',
            title: 'SCRT is having problems',
            service: {
              html_url: 'https://salesforce.pagerduty.com/services/PFGLA6A',
              id: 'PFGLA6A',
              self: 'https://api.pagerduty.com/services/PFGLA6A',
              summary: 'SEARCH test (Vijay Ignore)',
              type: 'service_reference'
            },
            assignees: [
              {
                html_url: 'https://salesforce.pagerduty.com/users/PKJXBVE',
                id: 'PKJXBVE',
                self: 'https://api.pagerduty.com/users/PKJXBVE',
                summary: 'Vijay Swamidass',
                type: 'user_reference'
              }
            ],
            escalation_policy: {
              html_url: 'https://salesforce.pagerduty.com/escalation_policies/P61I1Q5',
              id: 'P61I1Q5',
              self: 'https://api.pagerduty.com/escalation_policies/P61I1Q5',
              summary: 'Vijay Test',
              type: 'escalation_policy_reference'
            },
            teams: [],
            priority: nil,
            urgency: 'high',
            conference_bridge: nil,
            resolve_reason: nil,
            incident_type: {
              name: 'incident_default'
            }
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

    context 'when a valid PagerDuty Acknowledge webhook is received' do
      it 'creates a new Chat and Message' do
        post :receive, params: { id: webhook.id }, body: payload_ack, as: :json

        expect(response).to have_http_status(:created)

        chat = Chat.find_by(webhook_external_id: 'Q1VVXNR9VO48ZJ')
        expect(chat).not_to be_nil
        expect(chat.user_id).to eq(user.id)
        expect(chat.assistant).to eq(webhook.assistant)
        expect(chat.first_message).to eq(payload_ack)
        expect(chat.webhook_id).to eq(webhook.id)

        message = chat.messages.first
        expect(message.content).to eq(payload_ack)
        expect(message.user_id).to eq(user.id)
        expect(message.from.to_sym).to eq(:user)
      end
    end

    context 'when a valid PagerDuty Annotate webhook is received' do
      it 'creates a new Chat and Message' do
        post :receive, params: { id: webhook.id }, body: payload_annotate, as: :json

        expect(response).to have_http_status(:created)

        chat = Chat.find_by(webhook_external_id: 'Q1VVXNR9VO48ZJ')
        expect(chat).not_to be_nil
        expect(chat.user_id).to eq(user.id)
        expect(chat.assistant).to eq(webhook.assistant)
        expect(chat.first_message).to eq(payload_annotate)
        expect(chat.webhook_id).to eq(webhook.id)

        message = chat.messages.first
        expect(message.content).to eq(payload_annotate)
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
