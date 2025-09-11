# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:user) { create(:user) }
  let(:document) { create(:document) }
  let(:comment) { create(:comment, document: document, user: user) }

  before do
    session[:user_id] = user.id
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new comment' do
        expect do
          post :create, params: { document_id: document.id, comment: { content: 'Great document!' } }
        end.to change(Comment, :count).by(1)
      end

      it 'redirects to the document' do
        post :create, params: { document_id: document.id, comment: { content: 'Great document!' } }
        expect(response).to redirect_to(document)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a comment' do
        expect do
          post :create, params: { document_id: document.id, comment: { content: '' } }
        end.not_to change(Comment, :count)
      end
    end
  end

  describe 'PATCH #update' do
    context 'when user owns the comment' do
      it 'updates the comment' do
        patch :update, params: { document_id: document.id, id: comment.id, comment: { content: 'Updated content' } }
        comment.reload
        expect(comment.content).to eq('Updated content')
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when user owns the comment' do
      it 'deletes the comment' do
        comment # create the comment
        expect do
          delete :destroy, params: { document_id: document.id, id: comment.id }
        end.to change(Comment, :count).by(-1)
      end
    end
  end
end
