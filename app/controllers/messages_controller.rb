class MessagesController < BaseMessagesController
  # GET /messages or /messages.json
  def index
    @messages = if @chat
                  @chat.messages.order(created_at: :asc)
                else
                  Message.all.order(created_at: :asc)
                end

    @messages
  end

  # GET /messages/new
  def new
    @message = Message.new
  end

  # GET /messages/1/edit
  def edit; end
end
