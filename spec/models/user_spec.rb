# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'calculating user properties' do
    it 'is not valid with a short password' do
      # Create a user with a short password
      user = build(:user, password: 'Short1!')

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must be at least 8 characters long')
    end

    it 'is not valid with a missing number' do
      # Create a user with a short password
      user = build(:user, password: 'Shortpassword!')

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must contain at least one digit')
    end
  end
end
