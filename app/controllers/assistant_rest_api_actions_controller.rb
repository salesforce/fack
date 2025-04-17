class AssistantRestApiActionsController < ApplicationController
  before_action :set_assistant
  before_action :set_api_action, only: %i[show edit update destroy]

  def index
    @api_actions = @assistant.assistant_rest_api_actions
  end

  def show; end

  def new
    @api_action = @assistant.assistant_rest_api_actions.build
  end

  def edit; end

  def create
    @api_action = @assistant.assistant_rest_api_actions.build(api_action_params)

    if @api_action.save
      redirect_to assistant_assistant_rest_api_actions_path(@assistant), notice: 'API action was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @api_action.update(api_action_params)
      redirect_to assistant_assistant_rest_api_actions_path(@assistant), notice: 'API action was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @api_action.destroy
    redirect_to assistant_assistant_rest_api_actions_path(@assistant), notice: 'API action was successfully deleted.'
  end

  private

  def set_assistant
    @assistant = Assistant.find(params[:assistant_id])
  end

  def set_api_action
    @api_action = @assistant.assistant_rest_api_actions.find(params[:id])
  end

  def api_action_params
    params.require(:assistant_rest_api_action).permit(:endpoint, :authorization_header)
  end
end
