# frozen_string_literal: true

class DocumentsController < BaseDocumentsController
  include NeighborConcern

  # GET /documents/new
  def new
    @document = Document.new
  end

  # GET /documents/1/edit
  def edit
    authorize @document
  end

  # GET /documents/1 or /documents/1.json
  def show
    @related_docs = related_documents(@document).first(5)
    @related_questions = @document.questions.limit(5)
  end
end
