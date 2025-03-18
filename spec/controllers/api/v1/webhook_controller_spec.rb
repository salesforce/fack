require "rails_helper"

RSpec.describe Api::V1::WebhooksController, type: :controller do
  describe "POST #receive" do
    let(:tagline) { "SPECIAL_TAGLINE" }
    let(:user) { create(:user) }
    let(:library) { Library.create!(name: "My Library", user:) }
    let(:document) { create(:document) }

    let(:assistant) { create(:assistant, name: "genai_assistant", user:) }
    let(:webhook) { create(:webhook, hook_type: :pagerduty, assistant:, library:) }

    let(:payload_with_resolution_note) do
      {
        event: {
          id: "01FEW8TGIDWE21FOHP5WGIHUSX",
          event_type: "incident.annotated",
          resource_type: "incident",
          data: {
            content: "Resolution Note: Restarted the cluster.",
            incident: {
              html_url: "https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ",
              id: "Q1VVXNR9VO48ZJ",
              self: "https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ0",
              summary: "Argus is down (TEST)",
              type: "incident_reference",
            },
          },
        },
      }.to_json
    end

    let(:payload_with_tagline) do
      {
        event: {
          id: "01FEW8TGIDWE21FOHP5WGIHUSX",
          event_type: "incident.annotated",
          resource_type: "incident",
          data: {
            content: "This is a test with #{tagline}",
            incident: {
              html_url: "https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ",
              id: "Q1VVXNR9VO48ZJ",
              self: "https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ0",
              summary: "Argus is down (TEST)",
              type: "incident_reference",
            },
          },
        },
      }.to_json
    end

    let(:payload_resolved) do
      {
        event: {
          id: "01FEW8TGIDWE21FOHP5WGIHUSX",
          event_type: "incident.resolved",
          resource_type: "incident",
          occurred_at: "2025-01-30T21:00:00Z",
          data: {
            id: "Q1VVXNR9VO48ZJ",
            html_url: "https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ",
            created_at: "2025-01-30T20:46:49Z",
            title: "SCRT is having problems",
          },
        },
      }.to_json
    end

    let(:payload_without_tagline) do
      {
        event: {
          id: "01FEW8TGIDWE21FOHP5WGIHUSX",
          event_type: "incident.annotated",
          resource_type: "incident",
          data: {
            content: "This is a test without any special tagline",
            incident: {
              html_url: "https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ",
              id: "Q1VVXNR9VO48ZJ",
              self: "https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ0",
              summary: "Argus is down (TEST)",
              type: "incident_reference",
            },
          },
        },
      }.to_json
    end

    let(:payload_annotate) do
      {
        event: {
          id: "01FEW58JJ3A39M88ZUXISESOY8",
          event_type: "incident.annotated",
          resource_type: "incident",
          occurred_at: "2025-01-30T20:03:42.196Z",
          agent: {
            html_url: "https://salesforce.pagerduty.com/users/PKJXBVE",
            id: "PKJXBVE",
            self: "https://api.pagerduty.com/users/PKJXBVE",
            summary: "Vijay Swamidass",
            type: "user_reference",
          },
          client: {},
          data: {
            incident: {
              html_url: "https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ",
              id: "Q1VVXNR9VO48ZJ",
              self: "https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ0",
              summary: "Argus is down (TEST)",
              type: "incident_reference",
            },
            id: "PEUPADO",
            content: "This is a test.",
            trimmed: false,
            type: "incident_note",
          },
        },
      }.to_json
    end

    let(:payload_ack) do
      {
        event: {
          id: "01FEW8TGIDWE21FOHP5WGIHUSX",
          event_type: "incident.acknowledged",
          resource_type: "incident",
          occurred_at: "2025-01-30T20:46:57.114Z",
          agent: {
            html_url: "https://salesforce.pagerduty.com/users/PKJXBVE",
            id: "PKJXBVE",
            self: "https://api.pagerduty.com/users/PKJXBVE",
            summary: "Vijay Swamidass",
            type: "user_reference",
          },
          client: nil,
          data: {
            id: "Q1VVXNR9VO48ZJ",
            type: "incident",
            self: "https://api.pagerduty.com/incidents/Q1VVXNR9VO48ZJ",
            html_url: "https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ",
            number: 13_541_962,
            status: "acknowledged",
            incident_key: "[FILTERED]",
            created_at: "2025-01-30T20:46:49Z",
            title: "SCRT is having problems",
            service: {
              html_url: "https://salesforce.pagerduty.com/services/PFGLA6A",
              id: "PFGLA6A",
              self: "https://api.pagerduty.com/services/PFGLA6A",
              summary: "SEARCH test (Vijay Ignore)",
              type: "service_reference",
            },
            assignees: [
              {
                html_url: "https://salesforce.pagerduty.com/users/PKJXBVE",
                id: "PKJXBVE",
                self: "https://api.pagerduty.com/users/PKJXBVE",
                summary: "Vijay Swamidass",
                type: "user_reference",
              },
            ],
            escalation_policy: {
              html_url: "https://salesforce.pagerduty.com/escalation_policies/P61I1Q5",
              id: "P61I1Q5",
              self: "https://api.pagerduty.com/escalation_policies/P61I1Q5",
              summary: "Vijay Test",
              type: "escalation_policy_reference",
            },
            teams: [],
            priority: nil,
            urgency: "high",
            conference_bridge: nil,
            resolve_reason: nil,
            incident_type: {
              name: "incident_default",
            },
          },
        },
      }.to_json
    end

    before do
      allow(ENV).to receive(:fetch).with("WEBHOOK_TAGLINE", "").and_return(tagline)
      allow(ENV).to receive(:fetch).with("PAGERDUTY_API_TOKEN").and_return("XXX")
      request.headers["Authorization"] = "Token #{webhook.secret_key}" # Construct the auth header
      request.headers["Content-Type"] = "application/json"
    end

    context "when an invalid token is provided" do
      it "returns an unauthorized error" do
        request.headers["Authorization"] = "Token #{webhook.secret_key}XXX"
        post :receive, params: { id: webhook.id }, body: payload_ack, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when no token is provided" do
      it "returns an unauthorized error" do
        request.headers["Authorization"] = "Token #{webhook.secret_key}XXX"
        post :receive, params: { id: webhook.id }, body: payload_ack, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when a valid PagerDuty Acknowledge webhook is received" do
      it "creates a new Chat and Message" do
        post :receive, params: { id: webhook.id }, body: payload_ack, as: :json

        expect(response).to have_http_status(:created)

        parsed_payload_ack = JSON.parse(payload_ack)

        chat = Chat.find_by(webhook_external_id: "Q1VVXNR9VO48ZJ")
        expect(chat).not_to be_nil
        expect(chat.user_id).to eq(user.id)
        expect(chat.assistant).to eq(webhook.assistant)
        message_text = "Incident Q1VVXNR9VO48ZJ acknowledged: " + parsed_payload_ack["event"]["data"]["title"] + " \n<https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ|View Incident>"
        expect(chat.first_message).to eq(message_text)
        expect(chat.webhook_id).to eq(webhook.id)

        message = chat.messages.first
        expect(message.content).to eq(message_text)
        expect(message.user_id).to eq(user.id)
        expect(message.from.to_sym).to eq(:user)
      end
    end

    context "when an invalid webhook is received" do
      it "does not create a new Chat or Message" do
        invalid_payload = {
          event: {
            resource_type: "service", # Not an 'incident'
          },
        }.to_json

        post :receive, params: { id: webhook.id }, body: invalid_payload

        expect(response).to have_http_status(:no_content)
        expect(Chat.count).to eq(0)
      end
    end

    # This prevents loops in the annotation/webhook flow
    context "when the tagline is present in the payload" do
      it "does not create a new Chat or Message" do
        post :receive, params: { id: webhook.id }, body: payload_with_tagline, as: :json

        expect(response).to have_http_status(:no_content)
        expect(Chat.count).to eq(0)
      end
    end

    context "when an incident is resolved and a chat exists" do
      it "adds a message to the existing chat" do
        chat = Chat.create!(
          user:,
          assistant: webhook.assistant,
          webhook_id: webhook.id,
          webhook_external_id: "Q1VVXNR9VO48ZJ",
          first_message: "Incident: SCRT is having problems",
        )

        post :receive, params: { id: webhook.id }, body: payload_resolved, as: :json

        expect(response).to have_http_status(:created)
        chat.reload

        message_text = "Incident Q1VVXNR9VO48ZJ resolved. Start: 2025-01-30T20:46:49Z, End: 2025-01-30T21:00:00Z \n" \
                       "<https://salesforce.pagerduty.com/incidents/Q1VVXNR9VO48ZJ|View Incident>"

        expect(chat.messages.last.content).to eq(message_text)
      end
    end

    context "when an incident is resolved and no chat exists" do
      it "does not create a new chat" do
        expect do
          post :receive, params: { id: webhook.id }, body: payload_resolved, as: :json
        end.not_to change(Chat, :count)

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
