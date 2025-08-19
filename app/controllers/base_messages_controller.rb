class BaseMessagesController < ApplicationController
  before_action :set_message, only: %i[show edit update destroy]
  before_action :set_chat

  # GET /messages or /messages.json
  def index
    @messages = if @chat
                  @chat.messages.order(created_at: :asc)
                else
                  Message.all.order(created_at: :asc)
                end

    @messages
  end

  # GET /messages/1 or /messages/1.json
  def show; end

  # POST /messages or /messages.json
  def create
    @message = Message.new(message_params)
    @message.chat_id = @chat.id
    @message.user_id = current_user.id
    @message.from = :user

    respond_to do |format|
      if @message.save
        format.html { redirect_to @chat }
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @message.errors, status: :unprocessable_content }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_message
    @message = Message.find(params[:id])
  end

  def set_chat
    if params[:chat_id].present?
      @chat = Chat.find(params[:chat_id])
    elsif @message&.chat
      @chat = @message.chat
    end
  end

  # Only allow a list of trusted parameters through.
  def message_params
    params.require(:message).permit(:chat_id, :content, :from)
  end
end
