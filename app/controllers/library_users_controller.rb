class LibraryUsersController < ApplicationController
  before_action :set_library_user, only: %i[destroy]

  def new
    @library = Library.find(params[:library_id])
    @library_user = @library.library_users.build

    authorize @library_user
  end

  def index
    @library = Library.find(params[:library_id])
    @users = @library.users

    respond_to do |format|
      format.html # renders users.html.erb
      format.json { render json: @users }
    end
  end

  def create
    @library = Library.find(params[:library_id])
    @library_user = @library.library_users.build(library_user_params)

    authorize @library_user

    if @library_user.save
      redirect_to library_library_users_path(@library), notice: 'Library user was successfully created.'
    else
      render :new
    end
  end

  def destroy
    authorize @library_user

    @library_user.destroy!

    respond_to do |format|
      format.html { redirect_to library_library_users_path(@library_user.library_id), notice: 'Library user removed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_library_user
    @library_user = LibraryUser.find_by(user_id: params[:id], library_id: params[:library_id])
  end

  def library_user_params
    params.require(:library_user).permit(:user_id)
  end
end
