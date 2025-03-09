require 'rails_helper'
require 'openssl'

RSpec.describe SlackController, type: :request do
  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }

  # Assuming the Assistant model requires these fields
  let(:library) { Library.create!(name: 'Test Library', user:) }
  let(:assistant) { Assistant.create!(name: 'Test Assistant', user:, libraries: '1,2', input: 'Sample input', instructions: 'Sample instructions', output: 'Sample output') }

  let(:slack_signing_secret) { 'test_secret' }
  let(:slack_service) { instance_double(SlackService, bot_id: 'U123456') }
  let(:timestamp) { Time.now.to_i.to_s }
  let(:slack_signature) { generate_slack_signature(slack_signing_secret, timestamp, payload.to_json) }
  let(:headers) do
    {
      'X-Slack-Signature' => slack_signature,
      'X-Slack-Request-Timestamp' => timestamp,
      'CONTENT_TYPE' => 'application/json'
    }
  end

  before do
    allow(ENV).to receive(:fetch).with('SLACK_SIGNING_SECRET', nil).and_return(slack_signing_secret)
    allow(SlackService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:add_reaction) # Stub add_reaction to prevent unexpected message error
  end

  describe 'POST /slack/events' do
    context 'when handling URL verification' do
      let(:payload) { { type: 'url_verification', challenge: 'challenge_token' } }

      it 'responds with the challenge token' do
        post('/slack/events', params: payload.to_json, headers:)
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq('challenge' => 'challenge_token')
      end
    end

    context 'when receiving an app mention' do
      let(:payload) do
        {
          type: 'event_callback',
          event: {
            type: 'app_mention',
            user: 'U999999',
            text: '<@U123456> Hello!',
            channel: 'random',
            ts: '1234567890.123456'
          }
        }
      end

      before do
        allow(Assistant).to receive(:find_by).with(slack_channel_name: 'random').and_return(assistant)
      end

      it 'creates a new chat if one does not exist' do
        expect do
          post '/slack/events', params: payload.to_json, headers:
        end.to change(Chat, :count).by(1)
      end

      it 'removes the bot mention from the message text and trims whitespace' do
        post('/slack/events', params: payload.to_json, headers:)
        expect(Chat.last.first_message).to eq('Hello!')
      end
    end
  end

  def generate_slack_signature(secret, timestamp, body)
    sig_basestring = "v0:#{timestamp}:#{body}"
    'v0=' + OpenSSL::HMAC.hexdigest('sha256', secret, sig_basestring)
  end
end
