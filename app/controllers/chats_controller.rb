class ChatsController < ApplicationController
  before_action :set_chat, only: %i[show edit update destroy]

  # GET /chats or /chats.json
  def index
    @chats = Chat.all.page(params[:page])
  end

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

  # POST /chats or /chats.json
  def create
    @assistant = Assistant.find(params[:assistant_id])
    @chat = @assistant.chats.new(chat_params) # Assuming `chats` is the relationship between Assistant and Chat
    @chat.user_id = @current_user.id

    respond_to do |format|
      if @chat.save
        @chat.messages.create(content: @chat.first_message, user_id: @current_user.id, from: :user)
        format.html { redirect_to chat_url(@chat) }
        format.json { render :show, status: :created, location: @chat }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chat.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chats/1 or /chats/1.json
  def destroy
    @chat.destroy!

    respond_to do |format|
      format.html { redirect_to chats_url, notice: 'Chat was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_chat
    @chat = Chat.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def chat_params
    params.require(:chat).permit(:assistant_id, :first_message)
  end
end
