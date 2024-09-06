require 'rails_helper'

RSpec.describe 'chats', type: :view do
  let(:chat) { create(:chat, chat: 'Hello World') }

  before do
    assign(:chat, chat)
  end

  context 'when rendering the full view' do
    it 'renders chat attributes in JSON' do
      render

      json = JSON.parse(rendered)

      # Verify the structure of the JSON
      expect(json).to include(
        'id' => chat.id,
        'chat' => chat.chat,
        'created_at' => chat.created_at.as_json,
        'updated_at' => chat.updated_at.as_json,
        'url' => assistant_url(chat)
      )
    end
  end

  context 'when rendering a partial' do
    it 'renders the chat partial correctly' do
      render partial: 'api/v1/chats/chat', locals: { chat: }

      json = JSON.parse(rendered)

      # Verify the partial's JSON content
      expect(json).to include(
        'id' => chat.id,
        'chat' => chat.chat,
        'created_at' => chat.created_at.as_json,
        'updated_at' => chat.updated_at.as_json
      )
    end
  end
end
