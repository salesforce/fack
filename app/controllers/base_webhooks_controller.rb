class BaseWebhooksController < ApplicationController
  before_action :set_webhook, only: %i[show edit update destroy]

  # GET /webhooks or /webhooks.json
  def index
    @webhooks = Webhook.all
  end

  # POST /webhooks or /webhooks.json
  def create
    @webhook = Webhook.new(webhook_params)

    authorize @webhook

    respond_to do |format|
      if @webhook.save
        format.html { redirect_to webhook_url(@webhook), notice: 'Webhook was successfully created.' }
        format.json { render :show, status: :created, location: @webhook }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @webhook.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /webhooks/1 or /webhooks/1.json
  def update
    authorize @webhook

    respond_to do |format|
      if @webhook.update(webhook_params)
        format.html { redirect_to webhook_url(@webhook), notice: 'Webhook was successfully updated.' }
        format.json { render :show, status: :ok, location: @webhook }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @webhook.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /webhooks/1 or /webhooks/1.json
  def destroy
    authorize @webhook

    @webhook.destroy!

    respond_to do |format|
      format.html { redirect_to webhooks_url, notice: 'Webhook was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_webhook
    @webhook = Webhook.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def webhook_params
    params.require(:webhook).permit(:name, :assistant_id, :hook_type, :library_id)
  end
end
