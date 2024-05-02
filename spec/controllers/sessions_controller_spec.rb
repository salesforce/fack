# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #index' do
    it 'returns a successful response' do
      sign_in
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid credentials' do
      it 'logs in the user and redirects to the root path' do
        post :create, params: { session: { email: user.email, password: user.password } }
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'with invalid credentials' do
      it 'does not log in the user and redirects to the login page with a notice' do
        post :create, params: { session: { email: user.email, password: 'wrongpassword' } }
        expect(session[:user_id]).to be_nil
        expect(response).to redirect_to(new_session_url)
        expect(flash[:notice]).to eq('Error logging in.')
      end
    end
  end

  describe 'POST #set_debug' do
    it 'sets the debug session value and redirects to root' do
      post :set_debug, params: { debug: 'true' }
      expect(session[:debug]).to eq('true')
      expect(response).to redirect_to(root_url)
    end
  end

  describe 'GET #logout' do
    it 'logs out the user and redirects to the root path' do
      session[:user_id] = user.id
      get :logout
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_url)
    end
  end
end
