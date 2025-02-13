require 'rails_helper'

RSpec.describe GenerateMessageResponseJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }

  # Assuming the Assistant model requires these fields
  let(:library) { Library.create!(name: 'Test Library', user:) }
  let(:assistant) do
    Assistant.create!(name: 'Test Assistant', user:, approval_keywords: 'lgtm, approve', libraries: '1,2', library_id: library.id, input: 'Sample input', instructions: 'Sample instructions',
                      output: 'Sample output')
  end

  let(:valid_attributes) { { first_message: 'Hello', assistant_id: assistant.id } }
  let(:invalid_attributes) { { first_message: '', assistant_id: nil } }
  let(:chat) { Chat.create!(valid_attributes.merge(user_id: user.id)) }
  let(:assistant_message) { create(:message, chat:, user:, from: 'assistant', content: 'Generated response') }
  let(:user_message) { create(:message, chat:, user:, from: 'user', content: 'What is fack?') }
  let(:user_approval_message) { create(:message, chat:, user:, from: 'user', content: 'lgtm') }

  before do
    allow_any_instance_of(GenerateMessageResponseJob).to receive(:get_generation).and_return('Generated response')
    allow_any_instance_of(GenerateMessageResponseJob).to receive(:get_embedding).and_return(Array.new(1536, 0.1))
  end

  describe '#perform' do
    context 'when message contains an approval keyword' do
      it 'creates an assistant message confirming document creation' do
        described_class.perform_now(user_message.id)

        expect do
          described_class.perform_now(user_approval_message.id)
        end.to change(Message, :count).by(2)

        llm_message = Message.last
        expect(llm_message.content).to include('✨ Saved document!')
        expect(llm_message.from).to eq('assistant')
      end
    end

    context 'when message does not contain an approval keyword' do
      let(:message) { create(:message, chat:, user:, content: 'Tell me something interesting', from: 'user') }

      it 'calls get_generation to generate a response' do
        expect_any_instance_of(GenerateMessageResponseJob).to receive(:get_generation).and_return('Generated response')
        described_class.perform_now(message.id)

        llm_message = Message.last
        expect(llm_message.content).to eq('Generated response')
      end
    end
  end
end
