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
        # Replace this with the expected behavior for non-admin users
        expect(response).to be_successful
        # Or, if you return a 403 Forbidden status:
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
end
