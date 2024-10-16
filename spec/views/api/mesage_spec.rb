require 'rails_helper'

RSpec.describe 'Messages API', type: :request do
  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }
  let(:library) { Library.create!(name: 'Test Library', user:) }
  let(:assistant) { Assistant.create!(name: 'Test Assistant', user:, libraries: '1,2', input: 'Sample input', instructions: 'Sample instructions', output: 'Sample output') }
  let(:chat) { Chat.create!(first_message: 'Hello', assistant:, user:) }
  let(:valid_attributes) { { content: 'This is a test message', user_id: user.id } }
  let(:invalid_attributes) { { content: '', user_id: nil } }

  before do
    # Assuming you have some authentication mechanism
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'POST /api/v1/chats/:chat_id/messages' do
    context 'with valid parameters' do
      it 'creates a new Message' do
        expect do
          post "/api/v1/chats/#{chat.id}/messages", params: { message: valid_attributes }
        end.to change(Message, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including('application/json'))
        json = JSON.parse(response.body)
        expect(json).to include(
          'content' => 'This is a test message',
          'user_id' => user.id
        )
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Message' do
        expect do
          post "/api/v1/chats/#{chat.id}/messages", params: { message: invalid_attributes }
        end.to change(Message, :count).by(0)
        expect(response.content_type).to match(a_string_including('application/json'))
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
