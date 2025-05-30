class BaseAssistantsController < ApplicationController
  before_action :set_assistant, only: %i[show edit update destroy]

  # GET /assistants or /assistants.json
  def index
    @assistants = if params[:filter] == 'my'
                    Assistant.where(user_id: current_user.id).order(status: :desc).page(params[:page])
                  else
                    Assistant.all.order(status: :desc).page(params[:page])
                  end
    @assistants = @assistants.search_by_text(params[:contains]) if params[:contains].present?
  end

  # POST /assistants or /assistants.json
  def create
    json = JSON.parse(params[:json]) if params[:json].present?
    @assistant = Assistant.new(json || assistant_params)

    # Only admins can set the user_id
    @assistant.user_id = current_user.id if @assistant.user_id.nil? || !current_user.admin?

    authorize @assistant

    respond_to do |format|
      if @assistant.save
        format.html { redirect_to assistant_url(@assistant), notice: 'Assistant was successfully created.' }
        format.json { render :show, status: :created, location: @assistant }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @assistant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /assistants/1 or /assistants/1.json
  def update
    authorize @assistant

    respond_to do |format|
      if @assistant.update(assistant_params)
        format.html { redirect_to assistant_url(@assistant), notice: 'Assistant was successfully updated.' }
        format.json { render :show, status: :ok, location: @assistant }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @assistant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /assistants/1 or /assistants/1.json
  def destroy
    @assistant.destroy!

    respond_to do |format|
      format.html { redirect_to assistants_url, notice: 'Assistant was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_assistant
    @assistant = Assistant.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def assistant_params
    params.require(:assistant).permit(:libraries, :library_search_text, :name, :input, :output, :context, :instructions, :description, :status, :quip_url, :confluence_spaces, :user_id,
                                      :slack_channel_name, :approval_keywords, :create_doc_on_approval, :disable_nonbot_chat, :library_id, :soql, :slack_reply_only, :slack_channel_name_starts_with, :enable_channel_join_message)
  end
end
