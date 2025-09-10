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

    # Handle upvote/downvote functionality (requires user to be logged in)
    if params[:upvote] && current_user
      authorize @document, :upvote?
      @document.liked_by current_user, vote_scope: 'rating'
    elsif params[:downvote] && current_user
      authorize @document, :downvote?
      @document.disliked_by current_user, vote_scope: 'rating'
    elsif params[:unvote] && current_user
      @document.unliked_by current_user, vote_scope: 'rating'
      @document.undisliked_by current_user, vote_scope: 'rating'
    end

    redirect_to action: :show if params[:flag] || params[:unflag] || params[:upvote] || params[:downvote] || params[:unvote]

    @related_docs = related_documents(@document).first(5)
    @comments = @document.comments.includes(:user).ordered
  end
end
