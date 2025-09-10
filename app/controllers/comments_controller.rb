# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_document
  before_action :set_comment, only: %i[update destroy]
  before_action :authenticate_user!

  # POST /documents/:document_id/comments
  def create
    @comment = @document.comments.build(comment_params)
    @comment.user = current_user

    authorize @comment

    respond_to do |format|
      if @comment.save
        format.html { redirect_to @document, notice: 'Comment was successfully added.' }
        format.json { render json: @comment, status: :created }
        format.turbo_stream
      else
        format.html { redirect_to @document, alert: 'Failed to add comment.' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /documents/:document_id/comments/:id
  def update
    authorize @comment

    respond_to do |format|
      if @comment.update(comment_params)
        format.html { redirect_to @document, notice: 'Comment was successfully updated.' }
        format.json { render json: @comment }
        format.turbo_stream
      else
        format.html { redirect_to @document, alert: 'Failed to update comment.' }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/:document_id/comments/:id
  def destroy
    authorize @comment
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to @document, notice: 'Comment was successfully deleted.' }
      format.json { head :no_content }
      format.turbo_stream
    end
  end

  private

  def set_document
    @document = Document.find(params[:document_id])
  end

  def set_comment
    @comment = @document.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end

  def authenticate_user!
    redirect_to root_path, alert: 'You must be logged in to comment.' unless current_user
  end
end
