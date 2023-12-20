class QuestionsController < BaseQuestionsController
  # GET /questions/1 or /questions/1.json
  def show
    # Enable a param to be passed from other systems (like slack) to mark this helpful to the current user
    @question.liked_by current_user if params[:mark_helpful]
    @question.unliked_by current_user if params[:clear_helpful]

    if params[:mark_helpful] || params[:clear_helpful]
      redirect_to action: :show
    end
  end

  # GET /questions/new
  def new
    @question = Question.new
  end
end
