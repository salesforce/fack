class QuestionsController < BaseQuestionsController
  # GET /questions/1 or /questions/1.json
  def show; end

  # GET /questions/new
  def new
    @question = Question.new
  end
end
