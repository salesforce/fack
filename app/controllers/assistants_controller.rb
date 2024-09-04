class AssistantsController < BaseAssistantsController
  before_action :set_assistant, only: %i[show edit update destroy]

  # GET /assistants/1 or /assistants/1.json
  def show; end

  # GET /assistants/new
  def new
    @assistant = Assistant.new
  end

  # GET /assistants/1/edit
  def edit; end
end
