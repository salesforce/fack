class ChatsController < BaseChatsController
  # GET /chats/1 or /chats/1.json
  def show
    @show_footer = false
  end

  # GET /chats/new
  def new
    @chat = Chat.new
    @chat.assistant = Assistant.find(params[:assistant_id])
  end

  # GET /chats/1/edit
  def edit; end
end
