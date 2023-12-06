class BaseLibrariesController < ApplicationController
  before_action :set_library, only: %i[show edit update destroy]
  before_action :can_manage_libraries?, only: %i[edit create update destroy]

  # GET /libraries or /libraries.json
  def index
    @libraries = Library.all
  end

  # POST /libraries or /libraries.json
  def create
    @library = Library.new(library_params)
    @library.user_id = current_user.id

    respond_to do |format|
      if @library.save
        format.html { redirect_to library_url(@library), notice: 'Library was successfully created.' }
        format.json { render :show, status: :created, location: @library }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @library.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /libraries/1 or /libraries/1.json
  def update
    respond_to do |format|
      if @library.update(library_params)
        format.html { redirect_to library_url(@library), notice: 'Library was successfully updated.' }
        format.json { render :show, status: :ok, location: @library }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @library.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /libraries/1 or /libraries/1.json
  def destroy
    @library.destroy

    respond_to do |format|
      format.html { redirect_to libraries_url, notice: 'Library was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Permission Checks.  Move to CanCan later
  def can_manage_libraries?
    return true if current_user.admin?

    handle_bad_authortization
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_library
    @library = Library.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def library_params
    params.require(:library).permit(:name)
  end
end
