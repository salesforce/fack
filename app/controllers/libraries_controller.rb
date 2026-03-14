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
  def show
    # Track view for authenticated users
    track_view(@library)

    # Batch document stats in a single query for big libraries (avoids 4+ separate queries)
    docs_scope = @library.documents
    @library_stats = docs_scope.pick(
      Arel.sql('COUNT(*)::int'),
      Arel.sql('COUNT(*) FILTER (WHERE enabled IS NOT TRUE)::int'),
      Arel.sql('COUNT(*) FILTER (WHERE embedding IS NULL)::int')
    ) || [0, 0, 0]
    @documents_count, @disabled_count, @without_embedding_count = @library_stats

    # Preload recent documents with library to avoid N+1 in doc_list; exclude heavy embedding/search_vector
    @recent_documents = docs_scope
      .select(Document.column_names.excluding('embedding', 'search_vector').map { |c| "documents.#{c}" }.join(', '))
      .order(created_at: :desc)
      .limit(5)
      .includes(:library)
  end

  def users
    @library = Library.find(params[:id])
    @users = @library.users

    respond_to do |format|
      format.html # renders users.html.erb
      format.json { render json: @users }
    end
  end

  def download
    # Fetch and order documents, then map them to the desired XML-like string format
    formatted_documents = @library.documents.order(:created_at).map do |doc|
      "<document>\n" +
        "  <title>#{CGI.escapeHTML(doc.title.to_s)}</title>\n" + # Escape title content
        "  <created_at>#{doc.created_at}</created_at>\n" +
        "  <url>#{ENV.fetch('ROOT_URL', '')}#{document_path(doc)}</url>\n" + # Ensure ROOT_URL defaults to empty string
        "  <body>#{CGI.escapeHTML(doc.document.to_s)}</body>\n" + # Escape document content
        '</document>'
    end

    # Join the formatted strings
    contents = formatted_documents.join("\n\n") # No specific separator needed between <document> blocks

    # Add a root element for valid XML structure
    final_contents = "<documents>\n#{contents}\n</documents>"

    send_data final_contents, filename: "#{@library.name.parameterize}-documents.xml", type: 'application/xml' # Change filename and type
  end
end
