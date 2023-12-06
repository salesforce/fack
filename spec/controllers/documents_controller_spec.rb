require 'rails_helper'

RSpec.describe DocumentsController, type: :controller do
  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }
  let(:library) { Library.create!(name: 'My Library', user:) }
  let(:valid_attributes) { { title: 'Document Title', document: 'Body', url: 'http://example.com/doc', length: 10, library_id: library.id, user_id: user.id } }
  let(:invalid_attributes) { { title: '', url: '' } }
  let(:admin) { User.create!(email: 'admin@example.com', password: 'Password1!', admin: true) }

  before do
    # Assuming @current_user is set similarly to LibrariesController in the example
    allow_any_instance_of(BaseDocumentsController).to receive(:current_user).and_return(admin)
  end

  describe 'POST #create' do
    context 'with an existing external ID' do
      it 'does not create a new Document if the external ID exists' do
        existing_document = Document.create!(valid_attributes.merge(external_id: 'existing_id'))
        expect do
          post :create, params: { document: valid_attributes.merge(external_id: 'existing_id') }
        end.to change(Document, :count).by(0)
      end

      it 'links to the existing document with the same external ID' do
        existing_document = Document.create!(valid_attributes.merge(external_id: 'existing_id'))
        post :create, params: { document: valid_attributes.merge(external_id: 'existing_id') }
        expect(assigns(:document)).to eq(existing_document)
      end
    end

    context 'with a new external ID' do
      it 'creates a new Document with the given external ID' do
        expect do
          post :create, params: { document: valid_attributes.merge(external_id: 'new_id') }
        end.to change(Document, :count).by(1)
        expect(Document.last.external_id).to eq('new_id')
      end
    end
  end

  describe 'GET #index' do
    it 'returns a success response' do
      Document.create! valid_attributes
      get :index
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Document' do
        expect do
          post :create, params: { document: valid_attributes }
        end.to change(Document, :count).by(1)
      end
    end

    context 'with invalid params' do
      it 'does not create a new Document' do
        expect do
          post :create, params: { document: invalid_attributes }
        end.to change(Document, :count).by(0)
      end
    end
  end

  describe 'PUT #update' do
    let(:new_attributes) { { title: 'New Title' } }

    context 'with valid params' do
      it 'updates the requested document' do
        document = Document.create! valid_attributes
        put :update, params: { id: document.to_param, document: new_attributes }
        document.reload
        expect(document.title).to eq('New Title')
      end
    end
  end

end
