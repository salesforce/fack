# frozen_string_literal: true

class LibrariesController < BaseLibrariesController
  # GET /libraries/new
  def new
    @library = Library.new
  end

  # GET /libraries/1/edit
  def edit
    authorize @library
  end

  # GET /libraries/1 or /libraries/1.json
  def show; end

  def users
    @library = Library.find(params[:id])
    @users = @library.users

    respond_to do |format|
      format.html # renders users.html.erb
      format.json { render json: @users }
    end
  end
end
