class BaseChatsController < ApplicationController
  before_action :set_chat, only: %i[show edit update destroy]

  # GET /chats or /chats.json
  def index
    @chats = if params[:all].present?
               Chat.includes(:assistant, :user).page(params[:page])
             else
               Chat.includes(:assistant, :user).where(user_id: current_user.id).page(params[:page])
             end
  end

  # POST /chats or /chats.json
  def create
    @chat = Chat.new(chat_params)
    @chat.user_id = current_user.id

    if assistant = Assistant.find_by(id: params[:assistant_id])
      @chat.assistant = assistant
    end

    respond_to do |format|
      if @chat.save
        @chat.messages.create(content: @chat.first_message, user_id: @chat.user_id, from: :user)
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
