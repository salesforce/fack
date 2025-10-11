# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Library, type: :model do
  # Assuming you have factories set up for Library and User
  let(:user) { create(:user) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      library = build(:library, user:)
      expect(library).to be_valid
    end

    it 'is not valid without a name' do
      library = build(:library, name: nil, user:)
      expect(library).not_to be_valid
    end

    it 'is valid with a description' do
      library = build(:library, description: 'A test library description', user:)
      expect(library).to be_valid
    end

    it 'is valid without a description' do
      library = build(:library, description: nil, user:)
      expect(library).to be_valid
    end
  end

  describe 'associations' do
    it 'should have many documents' do
      t = Library.reflect_on_association(:documents)
      expect(t.macro).to eq(:has_many)
    end

    it 'should belong to a user' do
      t = Library.reflect_on_association(:user)
      expect(t.macro).to eq(:belongs_to)
    end
  end
end
