require 'rails_helper'

RSpec.describe AssistantsController, type: :controller do
  let(:current_user) { User.create!(email: 'user@example.com', password: 'Password1!', admin: true) }
  let(:assistant) { Assistant.create!(name: 'Test Assistant', user: current_user, libraries: '1,2', input: 'Sample input', instructions: 'Sample instructions', output: 'Sample output') }

  before do
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  describe 'GET index' do
    it 'assigns all assistants to @assistants' do
      get :index
      expect(assigns(:assistants)).to eq([assistant])
    end
  end

  describe 'POST create' do
    it 'creates a new assistant' do
      expect do
        post :create, params: { assistant: { name: 'Test Assistant 1', user: current_user, input: 'input', output: 'output' } }
      end.to change(Assistant, :count).by(1)
    end
  end

  describe 'PATCH update' do
    it 'updates the assistant' do
      patch :update, params: { id: assistant.id, assistant: { name: 'Updated Assistant' } }
      assistant.reload
      expect(assistant.name).to eq('Updated Assistant')
    end
  end
end
