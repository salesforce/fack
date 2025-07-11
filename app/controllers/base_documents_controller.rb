# frozen_string_literal: true

class BaseDocumentsController < ApplicationController
  helper_method :can_manage_documents?
  before_action :set_document, only: %i[show edit update]

  include Hashable
  include GptConcern
  include NeighborConcern
  # GET /documents or /documents.json
  def index
    @documents = Document.includes(:library, :user)

    @documents = if params[:sort] == 'questions'
                   @documents.order(questions_count: :desc)
                 elsif params[:sort] == 'tokens'
                   @documents.order(token_count: :desc)
                 else
                   @documents.order(updated_at: :desc)
                 end

    library_id = params[:library_id]
    if library_id.present?
      @library = Library.find(params[:library_id])
      @documents = @documents.where(library_id: @library.id)
    end

    # Filter with param :since - validate format first
    if params[:since].present?
      begin
        since_date = parse_since_parameter(params[:since])
        @documents = @documents.where('updated_at > ?', since_date)
      rescue ArgumentError => e
        respond_to do |format|
          format.html { redirect_to documents_path, alert: "Invalid date format for 'since' parameter: #{e.message}" }
          format.json { render json: { error: "Invalid date format for 'since' parameter: #{e.message}" }, status: :bad_request }
        end
        return
      end
    end

    # Filter with param :until - validate format first
    if params[:until].present?
      begin
        until_date = parse_since_parameter(params[:until])
        @documents = @documents.where('updated_at < ?', until_date)
      rescue ArgumentError => e
        respond_to do |format|
          format.html { redirect_to documents_path, alert: "Invalid date format for 'until' parameter: #{e.message}" }
          format.json { render json: { error: "Invalid date format for 'until' parameter: #{e.message}" }, status: :bad_request }
        end
        return
      end
    end

    if params[:similar_to].present?
      embedding = get_embedding(params[:similar_to])
      # Get similar documents but preserve existing filters
      similar_docs = related_documents_from_embedding_by_libraries(embedding, library_id)
      # Apply the similarity search as an additional filter by getting the IDs
      similar_doc_ids = similar_docs.pluck(:id)
      @documents = @documents.where(id: similar_doc_ids)
    end

    @documents = @documents.search_by_title_and_document(params[:contains]) if params[:contains].present?
    @documents = @documents.page(params[:page]).per(params[:per_page] || 10)
  end

  def update
    begin
      # This will attempt to extract the parameters and will raise an error if something goes wrong
      params = document_params
    rescue ActionController::ParameterMissing => e
      respond_to do |format|
        format.html do
          render inline: '<html><body><h1>Error:</h1><p><%= h error %></p></body></html>', status: :bad_request,
                 locals: { error: e.message }
        end
        format.json { render json: { error: e.message }, status: :bad_request }
      end
    end

    authorize @document

    respond_to do |format|
      if @document.update(params)
        EmbedDocumentJob.set(priority: 5).perform_later(@document.id) if @document.previous_changes.include?('check_hash')

        format.html do
          redirect_to document_url(@document), notice: 'Document was successfully updated.'
        end
        format.json { render :show, status: :ok, location: @document }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # POST /documents or /documents.json
  def create
    begin
      # This will attempt to extract the parameters and will raise an error if something goes wrong
      params = document_params
    rescue ActionController::ParameterMissing => e
      return render json: { error: e.message }, status: :bad_request
    end

    # Proceed with the rest of your method using the safely extracted `params`
    external_id = params[:external_id]
    @document = Document.find_by_external_id(external_id) if external_id.present?

    if @document.nil?
      @document = Document.new(params)
      @document.user_id = current_user.id
    else
      @document.assign_attributes(params)
    end

    authorize @document

    respond_to do |format|
      if @document.save
        format.html do
          redirect_to document_url(@document), notice: 'Document was successfully created.'
        end
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
    params.require(:document).permit(:document, :title, :enabled, :external_id, :url, :library_id, :source_url)
  end

  # Parse and validate the :since parameter
  # Accepts ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ), RFC 3339, or simple date formats
  def parse_since_parameter(since_param)
    # URL decode the parameter first to handle encoded characters
    decoded_param = URI.decode_www_form_component(since_param)

    # Try ISO 8601 format first (most common for APIs)
    begin
      return DateTime.iso8601(decoded_param)
    rescue ArgumentError
      # Continue to other formats
    end

    # Try RFC 3339 format
    begin
      return DateTime.rfc3339(decoded_param)
    rescue ArgumentError
      # Continue to other formats
    end

    # Try common date formats
    date_formats = [
      '%Y-%m-%d %H:%M:%S',
      '%Y-%m-%d %H:%M:%S %z',
      '%Y-%m-%d %H:%M:%S %Z',
      '%Y-%m-%dT%H:%M:%S',
      '%Y-%m-%dT%H:%M:%S%z',
      '%Y-%m-%dT%H:%M:%S %z',
      '%Y-%m-%d',
      '%m/%d/%Y',
      '%m/%d/%Y %H:%M:%S'
    ]

    date_formats.each do |format|
      return DateTime.strptime(decoded_param, format)
    rescue ArgumentError
      next
    end

    # If none of the formats work, raise an error with helpful message
    raise ArgumentError, "Invalid date format. Please use ISO 8601 format (e.g., '2023-12-01T10:30:00Z') or common date formats. Received: #{since_param}"
  end
end
