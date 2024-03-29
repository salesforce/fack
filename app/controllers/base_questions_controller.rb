class BaseQuestionsController < ApplicationController
  before_action :set_question, only: %i[show edit update destroy]
  include NeighborConcern

  # GET /questions or /questions.json
  def index
    @questions = Question.order(created_at: :desc).page(params[:page])
  end

  # POST /questions or /questions.json
  def create
    @question = Question.new(question_params)
    @question.user_id = current_user.id
    @question.status = 'pending'

    respond_to do |format|
      if @question.save
        GenerateAnswerJob.perform_later(@question.id)

        format.html { redirect_to question_url(@question), notice: 'Question was successfully created.' }
        format.json { render :show, status: :created, location: @question }
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /questions/1 or /questions/1.json
  def update; end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_question
    @question = Question.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def question_params
    params.require(:question).permit(:question, :answer, :library_id, :source_url, library_ids_included: [])
  end
end
