class BaseDocumentsController < ApplicationController
  helper_method :can_manage_documents?
  before_action :set_document, only: %i[show edit update]
  before_action :can_manage_documents?, only: %i[edit create update]

  include Hashable

  # GET /documents or /documents.json
  def index
    @documents = Document.all.order(created_at: :desc)
    if params[:library_id].present?
      @library = Library.find(params[:library_id])
      @documents = @documents.where(library_id: params[:library_id])
    end

    if params[:contains].present?
      @documents = @documents.search_by_title_and_document(params[:contains])
    end
    @documents = @documents.page(params[:page])
  end

  def update
    if params[:toggle_disabled]
      @document.update(enabled: !@document.enabled)
    else
      @document.update(document_params)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to documents_path }
    end
  end

  # POST /documents or /documents.json
  def create
    # check if external id present
    external_id = document_params[:external_id]
    @document = Document.find_by_external_id(external_id) if external_id.present?

    if @document.nil?
      @document = Document.new(document_params)
      @document.user_id = current_user.id
    else
      @document.assign_attributes(document_params)
    end

    respond_to do |format|
      if @document.save
        # TODO: Check if document is changing before reembedding to save cost
        EmbedDocumentJob.perform_later(@document.id) if @document.previous_changes.include?('check_hash')

        format.html { redirect_to document_url(@document), notice: 'Document was successfully created.' }
        format.json { render :show, status: :created, location: @document }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def can_manage_documents?
    return true if current_user.admin?

    if params[:document][:library_id]
      library = Library.find(params[:document][:library_id])
      return true if library.user_id == current_user.id
    end

    handle_bad_authortization
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_document
    @document = Document.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def document_params
    params.require(:document).permit(:document, :title, :external_id, :url, :library_id)
  end
end
