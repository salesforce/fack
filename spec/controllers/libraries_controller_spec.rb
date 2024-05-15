# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibrariesController, type: :controller do
  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }
  let(:admin) { User.create!(email: 'admin@example.com', password: 'Password1!', admin: true) }
  let(:editor) { User.create!(email: 'editor@example.com', password: 'Password1!') }
  let(:library) { Library.create!(name: 'Library', user: admin) }
  let!(:library_user) { LibraryUser.create!(user: editor, library: library, role: :editor) }
  let(:valid_attributes) { { name: 'Library', user: admin } }

  context 'as an admin user' do
    before do
      allow_any_instance_of(LibrariesController).to receive(:current_user).and_return(admin)
    end

    describe 'GET #index' do
      it 'returns a success response' do
        Library.create! valid_attributes
        get :index
        expect(response).to be_successful
      end
    end

    describe 'POST #create' do
      it 'creates a new Library' do
        expect do
          post :create, params: { library: valid_attributes }
        end.to change(Library, :count).by(1)
      end
    end
  end

  context 'as a non-admin user' do
    before do
      allow_any_instance_of(LibrariesController).to receive(:current_user).and_return(user)
    end

    describe 'GET #index' do
      it 'returns a success response' do
        Library.create! valid_attributes
        get :index
        expect(response).to be_successful
      end
    end

    describe 'POST #create' do
      it 'does not create a new Library' do
        expect do
          post :create, params: { library: valid_attributes }
        end.to_not change(Library, :count)
      end

      it 'redirects to a certain page or renders an error' do
        post :create, params: { library: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  context 'as an editor user' do
    before do
      allow_any_instance_of(LibrariesController).to receive(:current_user).and_return(editor)
    end

    describe 'GET #index' do
      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end
    end

    describe 'POST #create' do
      it 'does not create a new Library' do
        expect do
          post :create, params: { library: valid_attributes }
        end.to_not change(Library, :count)
      end

      it 'redirects to a certain page or renders an error' do
        post :create, params: { library: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'PUT #update' do
      it 'allows the editor to update the library' do
        put :update, params: { id: library.id, library: { name: 'Updated Library' } }
        library.reload
        expect(library.name).to eq('Updated Library')
      end
    end
  end
end
