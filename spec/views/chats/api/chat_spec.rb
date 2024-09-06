require 'rails_helper'

RSpec.describe 'chats api', type: :view do
  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }

  # Assuming the Assistant model requires these fields
  let(:library) { Library.create!(name: 'Test Library', user:) }
  let(:assistant) { Assistant.create!(name: 'Test Assistant', user:, libraries: '1,2', input: 'Sample input', instructions: 'Sample instructions', output: 'Sample output') }

  let(:valid_attributes) { { first_message: 'Hello', assistant_id: assistant.id } }
  let(:invalid_attributes) { { first_message: '', assistant_id: nil } }
  let(:chat) { Chat.create!(valid_attributes.merge(user_id: user.id)) }

  before do
    assign(:chat, chat)
  end

  context 'when rendering a partial' do
    it 'renders the chat partial correctly' do
      render partial: 'api/v1/chats/chat', locals: { chat: }

      json = JSON.parse(rendered)

      # Verify the partial's JSON content
      expect(json).to include(
        'id' => chat.id,
        'created_at' => chat.created_at.as_json,
        'updated_at' => chat.updated_at.as_json
      )
    end
  end
end
