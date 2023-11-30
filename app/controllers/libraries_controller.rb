class LibrariesController < BaseLibrariesController  
  # GET /libraries/new
  def new
    @library = Library.new
  end

  # GET /libraries/1/edit
  def edit; end

  # GET /libraries/1 or /libraries/1.json
  def show; end
end
