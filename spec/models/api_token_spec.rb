require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  # Test for associations
  it { should belong_to(:user) }

  describe 'validations' do
    subject { FactoryBot.create(:api_token) }

    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_presence_of(:name) }

    it 'has a unique token' do
      first_api_token = create(:api_token)
      second_api_token = create(:api_token)

      expect(second_api_token.token).not_to be_nil
      expect(second_api_token.valid?).to be true
    end
  end


  describe 'Token generation' do
    let(:user) { create(:user) }
    let(:api_token) { ApiToken.create(name: 'Sample Token', user:) }

    it 'generates a unique token on create' do
      expect(api_token.token).not_to be_nil
      expect(api_token.token.size).to eq(32) # MD5 hexdigest length
    end

    it 'activates the token on create' do
      expect(api_token.active).to be true
    end
  end

end
