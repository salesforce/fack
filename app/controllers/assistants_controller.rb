class AssistantsController < BaseAssistantsController
  before_action :set_assistant, only: %i[show edit update destroy]

  # GET /assistants/1 or /assistants/1.json
  def show
    @chat = Chat.new
    @chat.assistant = Assistant.find(params[:id])
  end

  # GET /assistants/new
  def new
    @assistant = Assistant.new
    @assistant.user_id = current_user.id
  end

  # GET /assistants/1/edit
  def edit; end
end
