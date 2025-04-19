# spec/jobs/generate_answer_job_spec.rb
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateAnswerJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user, email: 'user@example.com', password: 'Password1!') }
  let(:library) { create(:library, name: 'Test Library', user:) }
  let(:question) { create(:question, user:, library_id: library.id, question: 'What is the meaning of life?', library_ids_included: [library.id]) }
  let(:doc1) { create(:document, user:, library_id: library.id, title: 'Doc 1', document: 'Life is 42.', created_at: 2.days.ago, token_count: 10) }
  let(:doc2) { create(:document, user:, library_id: library.id, title: 'Doc 2', document: 'Life is complex.', created_at: 1.day.ago, token_count: 15, enabled: true) }

  before do
    # Stub environment variables
    allow(ENV).to receive(:fetch).with('ROOT_URL', nil).and_return('http://example.com')
    allow(ENV).to receive(:[]).with('ALLOWED_ADDITIONAL_TOPICS').and_return('philosophy')
    allow(ENV).to receive(:[]).with('MAX_DOCS').and_return('7')
    allow(ENV).to receive(:fetch).with('MAX_PROMPT_DOC_TOKENS', '10_000').and_return('1000')
    allow(ENV).to receive(:[]).with('MT_DEBUG').and_return(nil)
    allow(ENV).to receive(:fetch).with('EMBED_DELAY', Document::DEFAULT_EMBED_DELAY).and_return(5)
    # Stub GptConcern methods
    allow_any_instance_of(GenerateAnswerJob).to receive(:get_embedding).and_return(Array.new(1536, 0.1))
    allow_any_instance_of(GenerateAnswerJob).to receive(:get_generation).and_return(
      "# ANSWER\nThe meaning of life is 42, according to Doc 1.\n\n# DOCUMENTS\n1. [Doc 2](http://example.com/documents/#{doc2.id})"
    )

    # Stub NeighborConcern method
    allow_any_instance_of(GenerateAnswerJob).to receive(:related_documents_from_embedding).and_return(Document.where(id: [doc1.id, doc2.id]))
  end

  describe '#perform' do
    context 'with a valid question' do
      it 'generates an answer and updates the question' do
        perform_enqueued_jobs { GenerateAnswerJob.perform_later(question.id) }

        question.reload
        expect(question.embedding).to eq(Array.new(1536, 0.1))
        expect(question.answer).to include('The meaning of life is 42')
        expect(question.prompt).to include('What is the meaning of life?')
        expect(question.status).to eq('generated')
        expect(question.generation_time).to be_present
        expect(question.generated_at).to be_present
        expect(question.documents).to include(doc2) # doc1 is disabled by default in factory
      end

      it 'limits documents to MAX_DOCS and MAX_PROMPT_DOC_TOKENS' do
        allow(ENV).to receive(:[]).with('MAX_DOCS').and_return('1')
        allow(ENV).to receive(:fetch).with('MAX_PROMPT_DOC_TOKENS', '10_000').and_return('20')

        perform_enqueued_jobs { GenerateAnswerJob.perform_later(question.id) }

        question.reload
        expect(question.prompt.scan('URL:').count).to eq(1) # Only 1 doc due to MAX_DOCS=1
        expect(question.prompt).to include(doc2.title) # doc2 fits within token limit
        expect(question.prompt).not_to include(doc1.title)
      end
    end

    context 'when no related documents are found' do
      before do
        allow_any_instance_of(GenerateAnswerJob).to receive(:related_documents_from_embedding).and_return(Document.none)
      end

      it 'includes "No documents available" in the prompt' do
        perform_enqueued_jobs { GenerateAnswerJob.perform_later(question.id) }

        question.reload
        expect(question.prompt).to include('No documents available')
      end
    end

    context 'when generation fails' do
      before do
        allow_any_instance_of(GenerateAnswerJob).to receive(:get_generation).and_raise(StandardError, 'API error')
      end

      it 'marks the question as failed' do
        perform_enqueued_jobs { GenerateAnswerJob.perform_later(question.id) }

        question.reload
        expect(question.status).to eq('failed')
      end
    end

    context 'when question is not found' do
      it 'raises an error and does not update anything' do
        expect do
          GenerateAnswerJob.new.perform(999)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
