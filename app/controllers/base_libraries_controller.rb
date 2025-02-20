# frozen_string_literal: true

class BaseLibrariesController < ApplicationController
  before_action :set_library, only: %i[show edit update destroy]

  # GET /libraries or /libraries.json
  def index
    @libraries = Library.all.order(name: :asc).page(params[:page])
    @libraries = @libraries.search_by_name(params[:contains]) if params[:contains].present?
  end

  # POST /libraries or /libraries.json
  def create
    @library = Library.new(library_params)
    @library.user_id ||= current_user.id

    authorize @library

    respond_to do |format|
      if @library.save
        format.html do
          redirect_to library_url(@library), notice: 'Library was successfully created.'
        end
        format.json { render :show, status: :created, location: @library }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @library.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /libraries/1 or /libraries/1.json
  def update
    authorize @library

    respond_to do |format|
      if @library.update(library_params)
        format.html do
          redirect_to library_url(@library), notice: 'Library was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @library }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @library.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_library
    @library = Library.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def library_params
    params.require(:library).permit(:name, :source_url, :user_id)
  end
end
