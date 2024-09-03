class AssistantsController < ApplicationController
  before_action :set_assistant, only: %i[show edit update destroy]

  # GET /assistants or /assistants.json
  def index
    @assistants = Assistant.all
  end

  # GET /assistants/1 or /assistants/1.json
  def show; end

  # GET /assistants/new
  def new
    @assistant = Assistant.new
  end

  # GET /assistants/1/edit
  def edit; end

  # POST /assistants or /assistants.json
  def create
    @assistant = Assistant.new(assistant_params)

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
    params.require(:assistant).permit(:libraries, :name, :input, :output, :context, :instructions, :description, :status, :quip_url, :confluence_spaces)
  end
end
