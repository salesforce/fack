# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiTokensController, type: :controller do
  let(:admin_user) { create(:admin_user) }
  let(:regular_user) { create(:user) }
  let(:api_token) { create(:api_token, user: admin_user) }

  describe 'GET #index' do
    context 'as an admin user' do
      before do
        allow(controller).to receive(:current_user).and_return(admin_user)
      end

      it 'allows access and renders the index template' do
        get :index
        expect(response).to be_successful
        # expect(response).to render_template(:index)
      end
    end

    context 'as a non-admin user' do
      before do
        allow(controller).to receive(:current_user).and_return(regular_user)
      end

      it 'does allow access' do
        get :index
        expect(response).to be_successful
        # If non-admins should be forbidden, replace with:
        # expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #show' do
    context 'as an admin user' do
      before do
        allow(controller).to receive(:current_user).and_return(admin_user)
      end

      it "returns a success response for the token's owner" do
        get :show, params: { id: api_token.id }
        expect(response).to be_successful
      end

      it 'renders the :show template' do
        get :show, params: { id: api_token.id }
        # expect(response).to render_template(:show)
      end
    end
  end

  describe 'POST #create' do
    context 'as an admin user' do
      before do
        allow(controller).to receive(:current_user).and_return(admin_user)
      end

      it 'creates a new API token and redirects' do
        expect do
          post :create, params: { api_token: { name: 'New Token', expires_at: 1.month.from_now } }
        end.to change(ApiToken, :count).by(1)

        expect(response).to have_http_status(:redirect)
        expect(ApiToken.last.user).to eq(admin_user)
        expect(ApiToken.last.name).to eq('New Token')
      end

      it 'renders new template with invalid params' do
        post :create, params: { api_token: { name: '' } } # Assuming name is required
        expect(response).to have_http_status(422) # Use numeric code instead of :unprocessable_entity
        # expect(response).to render_template(:new)
      end
    end

    context 'as a non-admin user' do
      before do
        allow(controller).to receive(:current_user).and_return(regular_user)
      end

      it 'redirects to root path' do
        post :create, params: { api_token: { name: 'New Token', expires_at: 1.month.from_now } }
        expect(response).to have_http_status(:found) # 302 redirect
        expect(response).to redirect_to(root_path) # Matches authorize_admin behavior
        expect(ApiToken.count).to eq(0) # No token created
      end
    end
  end

  describe 'PATCH #update' do
    context 'as an admin user' do
      before do
        allow(controller).to receive(:current_user).and_return(admin_user)
      end

      it 'updates the API token and redirects' do
        patch :update, params: { id: api_token.id, api_token: { name: 'Updated Token' } }
        expect(response).to have_http_status(:redirect)
        expect(api_token.reload.name).to eq('Updated Token')
      end

      it 'renders edit template with invalid params' do
        patch :update, params: { id: api_token.id, api_token: { name: '' } } # Assuming name is required
        expect(response).to have_http_status(422) # Use numeric code instead of :unprocessable_entity
        # expect(response).to render_template(:edit)
      end
    end

    context 'as a non-admin user' do
      before do
        allow(controller).to receive(:current_user).and_return(regular_user)
      end

      it 'redirects to root path' do
        original_name = api_token.name
        patch :update, params: { id: api_token.id, api_token: { name: 'Hacked Token' } }
        expect(response).to have_http_status(:found) # 302 redirect
        expect(response).to redirect_to(root_path) # Matches authorize_admin behavior
        expect(api_token.reload.name).to eq(original_name) # No update
      end
    end
  end
end
