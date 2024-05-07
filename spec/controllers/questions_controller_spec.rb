# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuestionsController, type: :controller do
  let(:user) { create(:user) }
  let(:library) { Library.create!(name: 'My Library', user:) }

  let(:valid_attributes) do
    { question: 'Sample Question', answer: 'Sample Answer', library_id: library.id, source_url: 'http://slack.com/thread/2' }
  end
  let(:invalid_attributes) { { question: '', answer: '', library_id: nil } }

  before do
    allow_any_instance_of(QuestionsController).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      Question.create! valid_attributes
      get :index
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Question' do
        expect do
          post :create, params: { question: valid_attributes }
        end.to change(Question, :count).by(1)
      end

      it 'redirects to the created question' do
        post :create, params: { question: valid_attributes }
        expect(response).to redirect_to(Question.last)
      end
    end

    context 'when the question saves successfully' do
      it 'enqueues an GenerateAnswerJob' do
        expect {
          post :create, params: { question: valid_attributes }
        }.to have_enqueued_job(GenerateAnswerJob).on_queue('default')
      end
    end

    context 'with invalid params' do
      it 'fails to create' do
        post :create, params: { question: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with include_libraries params' do
      let(:additional_library) { Library.create!(name: 'Additional Library', user:) }
      let(:attributes_with_libraries) do
        valid_attributes.merge(library_ids_included: [library.id])
      end

      it 'associates the question with specified libraries' do
        post :create, params: { question: attributes_with_libraries }
        question = Question.last
        expect(question.library_ids_included).to include(library.id.to_s)
      end
    end
  end
end
