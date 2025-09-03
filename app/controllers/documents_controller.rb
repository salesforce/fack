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
    # Handle flagging functionality (requires user to be logged in)
    if params[:flag] && current_user
      @document.disliked_by current_user, vote_scope: 'flag'
    elsif params[:unflag] && current_user
      @document.undisliked_by current_user, vote_scope: 'flag'
    end

    redirect_to action: :show if params[:flag] || params[:unflag]

    @related_docs = related_documents(@document).first(5)
  end
end
