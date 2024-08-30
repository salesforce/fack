# frozen_string_literal: true

class DocumentsController < BaseDocumentsController
  include NeighborConcern

  # GET /documents/new
  def new
    @document = Document.new
  end

  # GET /documents/1/edit
  def edit
    authorize @document
  end

  # GET /documents/1 or /documents/1.json
  def show
    @related_docs = related_documents(@document).first(5)

    client = Quip::Client.new(access_token: ENV.fetch('QUIP_TOKEN'))
    @user = client.get_authenticated_user
    @thread = client.get_thread('FKm1ACjmrhfX')

    puts 'TTILE' + @thread['thread']['title']

    puts 'DOC' + @thread['html']
    return

    query = Confluence::Query.new
    spaces = params[:spaces]
    query_string = params[:query]

    @results = query.query_confluence(spaces, query_string)
    puts @results.to_json
  end
end
