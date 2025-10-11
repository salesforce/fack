# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }

  # Ensure valid data for all required fields in the Assistant model
  let(:assistant) do
    create(:assistant,
           name: 'test assistant',
           input: 'Sample input',
           instructions: 'Sample instructions',
           output: 'Sample output',
           user:,
           libraries: '1,2,3') # Assuming libraries expects a CSV of numbers
  end

  let(:chat) { create(:chat, first_message: 'My message', user:, assistant:) }

  it 'is valid with valid attributes' do
    message = Message.new(content: 'Hello, how are you?', chat:, user:, from: :user)
    expect(message).to be_valid
  end

  it 'is not valid without content' do
    message = Message.new(content: nil, chat:, user:, from: :user)
    expect(message).not_to be_valid
  end

  it 'is not valid without a chat' do
    message = Message.new(content: 'Hello, how are you?', chat: nil, user:, from: :user)
    expect(message).not_to be_valid
  end

  it 'is not valid without a user' do
    message = Message.new(content: 'Hello, how are you?', chat:, user: nil, from: :user)
    expect(message).not_to be_valid
  end

  it 'is not valid without a from attribute' do
    message = Message.new(content: 'Hello, how are you?', chat:, user:, from: nil)
    expect(message).not_to be_valid
  end

  it 'is valid with a from attribute as :user' do
    message = Message.new(content: 'Hello, how are you?', chat:, user:, from: :user)
    expect(message).to be_valid
  end

  it 'is valid with a from attribute as :assistant' do
    message = Message.new(content: 'Hello, how are you?', chat:, user:, from: :assistant)
    expect(message).to be_valid
  end

  describe 'slack_reply_only functionality' do
    let(:slack_service) { instance_double(SlackService) }
    let(:slack_channel_id) { 'C1234567890' }
    let(:slack_ts) { '1234567890.123456' }

    before do
      allow(SlackService).to receive(:new).and_return(slack_service)
      allow(slack_service).to receive(:post_message).and_return(slack_ts)
      allow(slack_service).to receive(:add_reaction)
    end

    context 'when assistant has slack_reply_only enabled' do
      let(:assistant_with_reply_only) do
        create(:assistant,
               name: 'Reply Only Assistant',
               input: 'Sample input',
               instructions: 'Sample instructions',
               output: 'Sample output',
               user:,
               libraries: '1,2,3',
               slack_reply_only: true,
               slack_channel_name: slack_channel_id)
      end

      let(:chat_with_reply_only) { create(:chat, first_message: 'My message', user:, assistant: assistant_with_reply_only) }

      context 'and no existing slack thread' do
        it 'does not post assistant messages to slack' do
          message = create(:message, 
                          content: 'Assistant response', 
                          chat: chat_with_reply_only, 
                          user:, 
                          from: :assistant,
                          status: :ready)

          expect(SlackService).not_to have_received(:new)
          expect(message.slack_ts).to be_nil
        end

        it 'allows user messages to be posted to slack' do
          message = create(:message, 
                          content: 'User question', 
                          chat: chat_with_reply_only, 
                          user:, 
                          from: :user,
                          status: :ready)

          expect(SlackService).not_to have_received(:new)
          expect(slack_service).not_to have_received(:post_message).with(slack_channel_id, 'User question', nil, false)
        end
      end

      context 'and existing slack thread' do
        before do
          chat_with_reply_only.update!(slack_thread: slack_ts)
        end

        it 'allows assistant messages to be posted to existing thread' do
          message = create(:message, 
                          content: 'Assistant response in thread', 
                          chat: chat_with_reply_only, 
                          user:, 
                          from: :assistant,
                          status: :ready)

          expect(SlackService).to have_received(:new)
          expect(slack_service).to have_received(:post_message).with(slack_channel_id, 'Assistant response in thread', slack_ts, true)
        end

        it 'allows user messages to be posted to existing thread' do
          message = create(:message, 
                          content: 'User follow-up', 
                          chat: chat_with_reply_only, 
                          user:, 
                          from: :user,
                          status: :ready)

          expect(SlackService).to have_received(:new)
          expect(slack_service).to have_received(:post_message).with(slack_channel_id, 'User follow-up', slack_ts, false)
        end
      end
    end

    context 'when assistant has slack_reply_only disabled' do
      let(:assistant_normal) do
        create(:assistant,
               name: 'Normal Assistant',
               input: 'Sample input',
               instructions: 'Sample instructions',
               output: 'Sample output',
               user:,
               libraries: '1,2,3',
               slack_reply_only: false,
               slack_channel_name: slack_channel_id)
      end

      let(:chat_normal) { create(:chat, first_message: 'My message', user:, assistant: assistant_normal) }

      it 'allows assistant messages to start new threads' do
        message = create(:message, 
                        content: 'Assistant starting new thread', 
                        chat: chat_normal, 
                        user:, 
                        from: :assistant,
                        status: :ready)

        expect(SlackService).to have_received(:new)
        expect(slack_service).to have_received(:post_message).with(slack_channel_id, 'Assistant starting new thread', nil, true)
      end

      it 'allows user messages to start new threads' do
        message = create(:message, 
                        content: 'User starting new thread', 
                        chat: chat_normal, 
                        user:, 
                        from: :user,
                        status: :ready)

        expect(SlackService).to have_received(:new)
        expect(slack_service).to have_received(:post_message).with(slack_channel_id, 'User starting new thread', nil, false)
      end
    end

    context 'when assistant has no slack channel configured' do
      let(:assistant_no_slack) do
        create(:assistant,
               name: 'No Slack Assistant',
               input: 'Sample input',
               instructions: 'Sample instructions',
               output: 'Sample output',
               user:,
               libraries: '1,2,3',
               slack_reply_only: true,
               slack_channel_name: nil)
      end

      let(:chat_no_slack) { create(:chat, first_message: 'My message', user:, assistant: assistant_no_slack) }

      it 'does not attempt to post to slack regardless of reply_only setting' do
        message = create(:message, 
                        content: 'Message without slack', 
                        chat: chat_no_slack, 
                        user:, 
                        from: :assistant,
                        status: :ready)

        expect(SlackService).not_to have_received(:new)
        expect(message.slack_ts).to be_nil
      end
    end

    context 'when message is not ready' do
      let(:assistant_with_slack) do
        create(:assistant,
               name: 'Assistant with Slack',
               input: 'Sample input',
               instructions: 'Sample instructions',
               output: 'Sample output',
               user:,
               libraries: '1,2,3',
               slack_reply_only: false,
               slack_channel_name: slack_channel_id)
      end

      let(:chat_with_slack) { create(:chat, first_message: 'My message', user:, assistant: assistant_with_slack) }

      it 'does not post generating messages to slack' do
        message = create(:message, 
                        content: 'Generating response...', 
                        chat: chat_with_slack, 
                        user:, 
                        from: :assistant,
                        status: :generating)

        expect(SlackService).not_to have_received(:new)
        expect(message.slack_ts).to be_nil
      end
    end

    describe '#assistant_reply_only_mode_violated?' do
      let(:assistant_reply_only) do
        create(:assistant,
               name: 'Reply Only Assistant',
               input: 'Sample input',
               instructions: 'Sample instructions',
               output: 'Sample output',
               user:,
               libraries: '1,2,3',
               slack_reply_only: true,
               slack_channel_name: slack_channel_id)
      end

      let(:chat_reply_only) { create(:chat, first_message: 'My message', user:, assistant: assistant_reply_only) }

      it 'returns true when assistant is reply_only, message is from assistant, and no thread exists' do
        message = build(:message, 
                       content: 'Assistant response', 
                       chat: chat_reply_only, 
                       user:, 
                       from: :assistant)

        expect(message.send(:assistant_reply_only_mode_violated?)).to be true
      end

      it 'returns false when assistant is reply_only, message is from assistant, but thread exists' do
        chat_reply_only.update!(slack_thread: slack_ts)
        message = build(:message, 
                       content: 'Assistant response', 
                       chat: chat_reply_only, 
                       user:, 
                       from: :assistant)

        expect(message.send(:assistant_reply_only_mode_violated?)).to be false
      end

      it 'returns false when assistant is reply_only but message is from user' do
        message = build(:message, 
                       content: 'User message', 
                       chat: chat_reply_only, 
                       user:, 
                       from: :user)

        expect(message.send(:assistant_reply_only_mode_violated?)).not_to be false
      end

      it 'returns false when assistant is not reply_only' do
        assistant_normal = create(:assistant,
                                 name: 'Normal Assistant',
                                 input: 'Sample input',
                                 instructions: 'Sample instructions',
                                 output: 'Sample output',
                                 user:,
                                 libraries: '1,2,3',
                                 slack_reply_only: false,
                                 slack_channel_name: slack_channel_id)
        
        chat_normal = create(:chat, first_message: 'My message', user:, assistant: assistant_normal)
        message = build(:message, 
                       content: 'Assistant response', 
                       chat: chat_normal, 
                       user:, 
                       from: :assistant)

        expect(message.send(:assistant_reply_only_mode_violated?)).to be false
      end
    end

    describe 'error handling' do
      let(:assistant_with_slack) do
        create(:assistant,
               name: 'Assistant with Slack',
               input: 'Sample input',
               instructions: 'Sample instructions',
               output: 'Sample output',
               user:,
               libraries: '1,2,3',
               slack_reply_only: false,
               slack_channel_name: slack_channel_id)
      end

      let(:chat_with_slack) { create(:chat, first_message: 'My message', user:, assistant: assistant_with_slack) }

      it 'handles slack errors gracefully and updates message content' do
        allow(slack_service).to receive(:post_message).and_raise(StandardError.new('Slack API error'))
        
        message = create(:message, 
                        content: 'Original content', 
                        chat: chat_with_slack, 
                        user:, 
                        from: :assistant,
                        status: :ready)

        message.reload
        expect(message.content).to include('Original content')
        expect(message.content).to include('⚠️ Slack Error: Slack API error')
      end
    end
  end
end
