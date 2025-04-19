# frozen_string_literal: true

class QuestionsController < BaseQuestionsController
  # GET /questions/1 or /questions/1.json
  def show
    # Enable a param to be passed from other systems (like slack) to mark this helpful to the current user
    @question.liked_by current_user if params[:mark_helpful]
    @question.unliked_by current_user if params[:clear_helpful]

    redirect_to action: :show if params[:mark_helpful] || params[:clear_helpful]

    @libraries = if @question.library_ids_included.present?
                   Library.where(id: @question.library_ids_included)
                 else
                   Library.none
                 end
  end

  # GET /questions/new
  def new
    @question = Question.new
  end

  # POST /questions
  def create
    @question = Question.new(question_params)
    @question.user_id = current_user.id
    @question.status = 'pending'

    if @question.save
      GenerateAnswerJob.set(priority: 1).perform_later(@question.id)
      redirect_to question_path(@question), notice: 'Question was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end
end
