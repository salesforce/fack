require 'rails_helper'

RSpec.describe Api::V1::WebhooksController, type: :controller do
  describe 'POST #receive' do
    let(:tagline) { 'SPECIAL_TAGLINE' }
    let(:library) { Library.create!(name: 'My Library', user:) }
    let(:document) { create(:document) } # Or create(:document) if using FactoryBot

    let(:user) { create(:user) }
    let(:assistant) { create(:assistant, name: 'genai_assistant', user:) }
    let(:webhook) { create(:webhook, hook_type: :pagerduty, assistant:, library:) }

    let(:payload_with_resolution_note) do
      {
        event: {
          id: '01FEW8TGIDWE21FOHP5WGIHUSX',
          event_type: 'incident.annotated',
          resource_type: 'incident',
          data: {
            content: 'Resolution Note: Restarted the cluster.',
            incident: {
              html_url: 'https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ',
              id: 'Q1VVXNR9VO48ZJ',
              self: 'https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ0',
              summary: 'Argus is down (TEST)',
              type: 'incident_reference'
            }
          }
        }
      }.to_json
    end

    let(:payload_with_tagline) do
      {
        event: {
          id: '01FEW8TGIDWE21FOHP5WGIHUSX',
          event_type: 'incident.annotated',
          resource_type: 'incident',
          data: {
            content: "This is a test with #{tagline}",
            incident: {
              html_url: 'https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ',
              id: 'Q1VVXNR9VO48ZJ',
              self: 'https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ0',
              summary: 'Argus is down (TEST)',
              type: 'incident_reference'
            }
          }
        }
      }.to_json
    end

    let(:payload_without_tagline) do
      {
        event: {
          id: '01FEW8TGIDWE21FOHP5WGIHUSX',
          event_type: 'incident.annotated',
          resource_type: 'incident',
          data: {
            content: 'This is a test without any special tagline',
            incident: {
              html_url: 'https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ',
              id: 'Q1VVXNR9VO48ZJ',
              self: 'https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ0',
              summary: 'Argus is down (TEST)',
              type: 'incident_reference'
            }
          }
        }
      }.to_json
    end

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
      allow(ENV).to receive(:fetch).with('WEBHOOK_TAGLINE', '').and_return(tagline)
      allow(controller).to receive(:current_user).and_return(user)
      request.headers['Content-Type'] = 'application/json'
    end

    context 'when a valid PagerDuty Acknowledge webhook is received' do
      it 'creates a new Chat and Message' do
        post :receive, params: { id: webhook.id }, body: payload_ack, as: :json

        expect(response).to have_http_status(:created)

        parsed_payload_ack = JSON.parse(payload_ack)

        chat = Chat.find_by(webhook_external_id: 'Q1VVXNR9VO48ZJ')
        expect(chat).not_to be_nil
        expect(chat.user_id).to eq(user.id)
        expect(chat.assistant).to eq(webhook.assistant)
        message_text = 'title: ' + parsed_payload_ack['event']['data']['title']
        expect(chat.first_message).to eq(message_text)
        expect(chat.webhook_id).to eq(webhook.id)

        message = chat.messages.first
        expect(message.content).to eq(message_text)
        expect(message.user_id).to eq(user.id)
        expect(message.from.to_sym).to eq(:user)
      end
    end

    context 'when a valid PagerDuty Annotate webhook is received' do
      it 'creates a new Chat and Message' do
        post :receive, params: { id: webhook.id }, body: payload_annotate, as: :json

        expect(response).to have_http_status(:created)

        parsed_payload_annotate = JSON.parse(payload_annotate)

        chat = Chat.find_by(webhook_external_id: 'Q1VVXNR9VO48ZJ')
        expect(chat).not_to be_nil
        expect(chat.user_id).to eq(user.id)
        expect(chat.assistant).to eq(webhook.assistant)

        message_text = 'content: ' + parsed_payload_annotate['event']['data']['content']
        expect(chat.first_message).to eq(message_text)
        expect(chat.webhook_id).to eq(webhook.id)

        message = chat.messages.first
        expect(message.content).to eq(message_text)
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

    context 'when the tagline is not present in the payload' do
      it 'creates a new Chat and Message' do
        post :receive, params: { id: webhook.id }, body: payload_without_tagline, as: :json

        expect(response).to have_http_status(:created)

        parsed_payload_annotate = JSON.parse(payload_without_tagline)

        chat = Chat.find_by(webhook_external_id: 'Q1VVXNR9VO48ZJ')
        expect(chat).not_to be_nil

        message_text = 'content: ' + parsed_payload_annotate['event']['data']['content']
        expect(chat.first_message).to eq(message_text)

        message = chat.messages.first
        expect(message.content).to eq(message_text)
      end
    end

    # This prevents loops in the annotation/webhook flow
    context 'when the tagline is present in the payload' do
      it 'does not create a new Chat or Message' do
        post :receive, params: { id: webhook.id }, body: payload_with_tagline, as: :json

        expect(response).to have_http_status(:no_content)
        expect(Chat.count).to eq(0)
      end
    end

    it 'creates a new Document with the correct content and library association' do
      post :receive, params: { id: webhook.id }, body: payload_with_resolution_note, as: :json

      expect(response).to have_http_status(:created)

      parsed_payload = JSON.parse(payload_with_resolution_note)
      resolution_note_text = parsed_payload['event']['data']['content']
      incident_url = parsed_payload['event']['data']['incident']['html_url']
      incident_summary_text = parsed_payload['event']['data']['incident']['summary']

      doc_text = resolution_note_text + ' PD URL: ' + incident_url + ' Summary: ' + incident_summary_text

      # Fetch the created document (since we are now using the real creation process)
      created_doc = Document.last

      expect(created_doc).not_to be_nil
      expect(created_doc.document).to eq(doc_text)
      expect(created_doc.user_id).to eq(user.id)
      expect(created_doc.library_id).to eq(library.id)

      # Check validation by ensuring that title presence is required (should fail without it)
      expect(created_doc.valid?).to eq(false) if created_doc.title.blank?
    end
  end
end
