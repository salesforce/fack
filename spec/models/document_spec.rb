# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Document, type: :model do
  describe '#calculate_length' do
    it 'calculates the length of the document' do
      document = build(:document)
      document.calculate_length
      expect(document.length).to eq(document.document.length)
    end
  end

  describe '#calculate_tokens' do
    it 'calculates the token count of the document' do
      document = build(:document)
      expect(document).to receive(:count_tokens).with(document.document)
      document.calculate_tokens
    end
  end

  describe '#calculate_hash' do
    it 'calculates a SHA2 hash of the document' do
      document = build(:document)
      original_hash = Digest::SHA2.hexdigest(document.document)
      document.calculate_hash
      expect(document.check_hash).to eq(original_hash)
    end
  end

  describe 'source-backed document without a body' do
    it 'is valid on create with only a source_url' do
      document = build(:document, document: nil, source_url: 'https://example.com/doc')
      expect(document).to be_valid
      expect(document.length).to eq(0)
      expect(document.token_count).to eq(0)
    end

    it 'still requires a body when there is no source_url' do
      document = build(:document, document: nil, source_url: nil)
      expect(document).not_to be_valid
    end
  end
end
