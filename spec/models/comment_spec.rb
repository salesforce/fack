# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe 'associations' do
    it { should belong_to(:document) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_least(1).is_at_most(2000) }
    it { should validate_presence_of(:document) }
    it { should validate_presence_of(:user) }
  end

  describe 'scopes' do
    describe '.ordered' do
      it 'orders comments by created_at desc' do
        document = create(:document)
        user = create(:user)

        comment1 = create(:comment, document: document, user: user, created_at: 1.hour.ago)
        comment2 = create(:comment, document: document, user: user, created_at: 2.hours.ago)
        comment3 = create(:comment, document: document, user: user, created_at: 30.minutes.ago)

        expect(Comment.ordered).to eq([comment3, comment1, comment2])
      end
    end
  end
end
