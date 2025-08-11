class AssistantsController < BaseAssistantsController
  before_action :set_assistant, only: %i[show edit update destroy users]

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

  # GET /assistants/1/clone
  def clone
    original_assistant = Assistant.find(params[:id])
    @assistant = original_assistant.dup # Duplicate the original assistant

    @assistant.name = "Clone of #{original_assistant.name}"

    # Render the 'new' view, which will now be used for cloning/editing
    render :new
  end

  # GET /assistants/1/users
  def users
    redirect_to assistant_assistant_users_path(@assistant)
  end
end
