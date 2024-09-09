require 'rails_helper'
RSpec.describe 'Chats API', type: :request do
  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }
  let(:library) { Library.create!(name: 'Test Library', user:) }
  let(:assistant) { Assistant.create!(name: 'Test Assistant', user:, libraries: '1,2', input: 'Sample input', instructions: 'Sample instructions', output: 'Sample output') }
  let(:valid_attributes) { { first_message: 'Hello', assistant_id: assistant.id } }
  let(:invalid_attributes) { { first_message: '', assistant_id: nil } }

  before do
    # Assuming you have some authentication mechanism
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end
  describe 'POST /api/v1/chats' do
    context 'with valid parameters' do
      it 'creates a new Chat' do
        expect do
          post '/api/v1/chats', params: { chat: valid_attributes }
        end.to change(Chat, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including('application/json'))
        json = JSON.parse(response.body)
        expect(json).to include(
          'first_message' => 'Hello'
        )
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Chat' do
        expect do
          post '/api/v1/chats', params: { chat: invalid_attributes }
        end.to change(Chat, :count).by(0)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end
  end
end
