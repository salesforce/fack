# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatsController, type: :controller do
  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }

  # Assuming the Assistant model requires these fields
  let(:library) { Library.create!(name: 'Test Library', user:) }
  let(:assistant) { Assistant.create!(name: 'Test Assistant', libraries: '1,2', input: 'Sample input', instructions: 'Sample instructions', output: 'Sample output') }

  let(:valid_attributes) { { first_message: 'Hello', assistant_id: assistant.id } }
  let(:invalid_attributes) { { first_message: '', assistant_id: nil } }
  let(:chat) { Chat.create!(valid_attributes.merge(user_id: user.id)) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'filters chats by the current user when the all parameter is not present' do
      other_user = User.create!(email: 'otheruser@example.com', password: 'Password1!')
      other_chat = Chat.create!(valid_attributes.merge(user_id: other_user.id))
      get :index
      expect(assigns(:chats)).to eq([chat])
    end

    it 'returns all chats when the all parameter is present' do
      other_chat = Chat.create!(valid_attributes.merge(user_id: user.id, first_message: 'Another message'))
      get :index, params: { all: true }
      expect(assigns(:chats)).to match_array([chat, other_chat])
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { id: chat.to_param }
      expect(response).to be_successful
    end

    it 'sets @show_footer to false' do
      get :show, params: { id: chat.to_param }
      expect(assigns(:show_footer)).to be_falsey
    end
  end

  describe 'GET #new' do
    it 'assigns a new chat as @chat' do
      get :new, params: { assistant_id: assistant.id }
      expect(assigns(:chat)).to be_a_new(Chat)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Chat' do
        expect do
          post :create, params: { chat: valid_attributes, assistant_id: assistant.id }
        end.to change(Chat, :count).by(1)
      end

      it 'redirects to the created chat' do
        post :create, params: { chat: valid_attributes, assistant_id: assistant.id }
        expect(response).to redirect_to(Chat.last)
      end
    end

    context 'with invalid params' do
      it 'does not create a new Chat' do
        expect do
          post :create, params: { chat: invalid_attributes }
        end.to change(Chat, :count).by(0)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested chat' do
      chat_to_destroy = Chat.create!(valid_attributes.merge(user_id: user.id))
      expect do
        delete :destroy, params: { id: chat_to_destroy.to_param }
      end.to change(Chat, :count).by(-1)
    end

    it 'redirects to the chats list' do
      delete :destroy, params: { id: chat.to_param }
      expect(response).to redirect_to(chats_url)
    end
  end
end
