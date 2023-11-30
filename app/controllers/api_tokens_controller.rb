class ApiTokensController < ApplicationController
  before_action :set_api_token, only: %i[show edit update destroy]
  before_action :can_manage_tokens?

  # GET /api_tokens or /api_tokens.json
  def index
    @api_tokens = ApiToken.all.where(user_id: @current_user.id)
  end

  # GET /api_tokens/1 or /api_tokens/1.json
  def show
    return if @api_token.user.id != @current_user.id

    # Mark the token shown so we only show it once
    return if @api_token.shown_once

    # Get the current date and time
    current_time = DateTime.now

    # Subtract 1 minute
    time_one_minute_ago = current_time - (1.0 / 1440)

    @show_token = !@api_token.shown_once && @api_token.created_at > time_one_minute_ago

    @api_token.shown_once = true
    @api_token.save!
  end

  # GET /api_tokens/new
  def new
    @api_token = ApiToken.new
  end

  # GET /api_tokens/1/edit
  def edit; end

  # POST /api_tokens or /api_tokens.json
  def create
    @api_token = ApiToken.new(api_token_params)
    @api_token.user_id = current_user.id

    respond_to do |format|
      if @api_token.save
        format.html { redirect_to api_token_url(@api_token), notice: 'Api token was successfully updated.' }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /api_tokens/1 or /api_tokens/1.json
  def update
    respond_to do |format|
      if @api_token.update(api_token_params)
        format.html { redirect_to api_tokens_url, notice: 'Api token was successfully updated.' }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /api_tokens/1 or /api_tokens/1.json
  def destroy
    @api_token.destroy

    respond_to do |format|
      format.html { redirect_to api_tokens_url, notice: 'Api token was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_api_token
    @api_token = ApiToken.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def api_token_params
    params.require(:api_token).permit(:name)
  end
end
