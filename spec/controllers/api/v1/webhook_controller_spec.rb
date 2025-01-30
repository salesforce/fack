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
            content: "Based on the incident details provided, here are some helpful links and tips to resolve the issue:\n\n### Helpful Links:\n1. **PagerDuty Incident Details**: [Incident Q2L14QSCMS21O0](https://salesforce.pagerduty.com/incidents/Q2L14QSCMS21O0)\n2. **Service Details**: [SEARCH test (Vijay Ignore)](https://salesforce.pagerduty.com/services/PFGLA6A)\n3. **Escalation Policy**: [Vijay Test](https://salesforce.pagerduty.com/escalation_policies/P61I1Q5)\n\n### Tips to Solve the Problem:\n1. **Acknowledge the Incident**: Ensure the incident is acknowledged by the responsible team member. This has already been done by Vijay Swamidass.\n2. **Investigate the Root Cause**: Review the incident details and logs to identify the root cause of the issue. Since this is a test incident, ensure that all test parameters are correctly set.\n3. **Communication**: Keep all stakeholders informed about the status of the incident and any actions being taken.\n4. **Resolution Steps**: Follow the predefined resolution steps for similar incidents. If this is a new type of incident, document the steps taken for future reference.\n5. **Post-Incident Review**: Conduct a post-incident review to identify any gaps in the incident response process and update the incident management plan accordingly.\n\nIf you need further assistance, please refer to the provided links or contact the responsible team members.",
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
