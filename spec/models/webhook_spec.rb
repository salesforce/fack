require 'rails_helper'

RSpec.describe Webhook, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:assistant) }
    it { should belong_to(:library) }
    it { should have_many(:chats) }
  end

  describe 'validations' do
    it { should validate_presence_of(:hook_type) }
  end

  describe 'enums' do
    it { should define_enum_for(:hook_type).with_values(pagerduty: 0) }
  end

  describe 'callbacks' do
    context 'before_create' do
      it 'generates a secret key before creation' do
        webhook = Webhook.new(assistant: create(:assistant), library: create(:library), hook_type: :pagerduty)
        expect(webhook.secret_key).to be_nil # Should be nil before saving

        webhook.save!
        expect(webhook.secret_key).not_to be_nil
        expect(webhook.secret_key.length).to eq(40) # Ensuring it generates a 40-character key
      end
    end
  end
end
