# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }

  # Ensure valid data for all required fields in the Assistant model
  let(:assistant) do
    create(:assistant,
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
end
