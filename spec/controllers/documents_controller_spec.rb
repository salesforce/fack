# frozen_string_literal: true

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
        Document.create!(valid_attributes.merge(external_id: 'existing_id'))
        expect do
          post :create, params: { document: valid_attributes.merge(external_id: 'existing_id') }
        end.to change(Document, :count).by(0)
      end

      it 'links to the existing document with the same external ID' do
        existing_document = Document.create!(valid_attributes.merge(external_id: 'existing_id'))
        post :create,
             params: { document: valid_attributes.merge(title: 'new doc', document: 'new document body',
                                                        external_id: 'existing_id') }
        expect(assigns(:document)).to eq(existing_document)
        expect(Document.last.title).to eq('new doc')
      end
    end

    context 'when the document saves successfully' do
      it 'enqueues an EmbedDocumentJob' do
        expect do
          post :create, params: { document: valid_attributes }
        end.to have_enqueued_job(EmbedDocumentJob).on_queue('default')
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

    it 'filters documents by the contains parameter' do
      Document.create!(valid_attributes.merge(title: 'First Document', document: 'Content of the first document'))
      Document.create!(valid_attributes.merge(title: 'Second Document', document: 'Content including special keyword'))
      get :index, params: { contains: 'including keyword' }
      expect(assigns(:documents)).to match_array([Document.find_by(title: 'Second Document')])
    end

    context 'with show_deleted parameter' do
      let!(:active_document) { Document.create!(valid_attributes.merge(title: 'Active Document', document: 'Active document content')) }
      let!(:deleted_document) { Document.create!(valid_attributes.merge(title: 'Deleted Document', document: 'Deleted document content')) }

      before do
        deleted_document.soft_delete!
      end

      it 'shows only active documents by default' do
        get :index
        expect(assigns(:documents)).to include(active_document)
        expect(assigns(:documents)).not_to include(deleted_document)
      end

      it 'shows both active and deleted documents when show_deleted=true' do
        get :index, params: { show_deleted: 'true' }
        expect(assigns(:documents)).to include(active_document)
        expect(assigns(:documents)).to include(deleted_document)
      end

      it 'shows only deleted documents when show_deleted=only' do
        get :index, params: { show_deleted: 'only' }
        expect(assigns(:documents)).not_to include(active_document)
        expect(assigns(:documents)).to include(deleted_document)
      end
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

    context 'when current_user is the user of the associated library' do
      before do
        allow_any_instance_of(BaseDocumentsController).to receive(:current_user).and_return(user)
      end

      it 'creates a new Document' do
        expect do
          post :create, params: { document: valid_attributes }
        end.to change(Document, :count).by(1)
      end
    end

    context 'when current_user is not the user of the associated library' do
      let(:other_user) { User.create!(email: 'otheruser@example.com', password: 'Password1!') }
      before do
        allow_any_instance_of(BaseDocumentsController).to receive(:current_user).and_return(other_user)
      end

      it 'does not create a new Document' do
        expect do
          post :create, params: { document: valid_attributes }
        end.to change(Document, :count).by(0)
      end

      it 'returns an unauthorized response' do
        post :create, params: { document: valid_attributes }
        expect(response).to have_http_status(302)
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
