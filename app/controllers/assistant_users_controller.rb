class AssistantUsersController < ApplicationController
  before_action :set_assistant_user, only: %i[destroy]

  def new
    @assistant = Assistant.find(params[:assistant_id])
    @assistant_user = @assistant.assistant_users.build

    authorize @assistant_user
  end

  def index
    @assistant = Assistant.find(params[:assistant_id])
    @users = @assistant.users

    respond_to do |format|
      format.html # renders users.html.erb
      format.json { render json: @users }
    end
  end

  def create
    @assistant = Assistant.find(params[:assistant_id])
    @assistant_user = @assistant.assistant_users.build(assistant_user_params)

    authorize @assistant_user

    if @assistant_user.save
      redirect_to assistant_assistant_users_path(@assistant), notice: 'Assistant user was successfully created.'
    else
      render :new
    end
  end

  def destroy
    authorize @assistant_user

    @assistant_user.destroy!

    respond_to do |format|
      format.html { redirect_to assistant_assistant_users_path(@assistant_user.assistant_id), notice: 'Assistant user removed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_assistant_user
    @assistant_user = AssistantUser.find_by(user_id: params[:id], assistant_id: params[:assistant_id])
  end

  def assistant_user_params
    params.require(:assistant_user).permit(:user_id)
  end
end
