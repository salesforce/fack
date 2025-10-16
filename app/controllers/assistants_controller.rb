class AssistantsController < BaseAssistantsController
  before_action :set_assistant, only: %i[show edit update destroy users]

  # GET /assistants/1 or /assistants/1.json
  def show
    @chat = Chat.new
    @chat.assistant = Assistant.find(params[:id])

    # Prepare data for chats per day chart (last 30 days)
    @chats_per_day = prepare_chats_per_day_data(@assistant)
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

  private

  def prepare_chats_per_day_data(assistant)
    # Get last 30 days
    end_date = Date.today
    start_date = end_date - 60.days

    # Get chats grouped by day
    chats_by_day = assistant.chats
                            .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                            .group('DATE(created_at)')
                            .count

    # Fill in missing days with 0
    (start_date..end_date).map do |date|
      {
        date: date.strftime('%Y-%m-%d'),
        count: chats_by_day[date] || 0
      }
    end
  end
end
