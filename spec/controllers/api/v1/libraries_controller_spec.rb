# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::LibrariesController, type: :controller do
  let(:admin) { User.create!(email: 'admin@example.com', password: 'Password1!', admin: true) }
  let(:library) { Library.create!(name: 'Library', user: admin) }
  let(:api_token) { ApiToken.create!(user: admin, name: 'cli') }

  # The test environment disables CSRF protection, which would hide a missing
  # skip_before_action. API clients authenticate with a bearer token and never
  # have a CSRF token, so turn the protection back on to match production.
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    request.headers['Authorization'] = "Bearer #{api_token.token}"
    request.headers['Accept'] = 'application/json'
  end

  describe 'POST #create' do
    it 'does not require a CSRF token' do
      expect do
        post :create, params: { library: { name: 'New library' } }, format: :json
      end.to change(Library, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe 'PATCH #update' do
    it 'does not require a CSRF token' do
      patch :update, params: { id: library.id, library: { name: 'Renamed' } }, format: :json

      expect(response).to have_http_status(:ok)
      expect(library.reload.name).to eq('Renamed')
    end
  end
end
