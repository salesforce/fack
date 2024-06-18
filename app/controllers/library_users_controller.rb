class LibraryUsersController < ApplicationController
    def new
      @library = Library.find(params[:library_id])
      @library_user = @library.library_users.build
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
  
    private
  
    def library_user_params
      params.require(:library_user).permit(:user_id)
    end
  end
  