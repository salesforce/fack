# frozen_string_literal: true

# MCP Server-Sent Events (SSE) Controller
# Implements the MCP protocol directly in Rails so clients can connect via HTTP
# No local MCP server needed - just provide a URL!
class McpSseController < ApplicationController
  include ActionController::Live
  
  # Skip CSRF for MCP protocol endpoints
  skip_before_action :verify_authenticity_token
  
  # Allow SSE connections from any origin (CORS)
  before_action :set_sse_headers, only: [:sse]

  # GET /mcp/sse
  # Main SSE endpoint for MCP protocol
  # Clients connect here and communicate via JSON-RPC over SSE
  def sse
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'
    
    # Get token from query param or Authorization header
    token = params[:token] || extract_bearer_token
    
    unless token && valid_token?(token)
      sse_write.call('error', { error: 'Invalid or missing token' }.to_json)
      response.stream.close
      return
    end
    
    @current_user = ApiToken.find_by(token: token, active: true)&.user
    
    # Send initial connection success
    sse_write.call('connected', { message: 'Connected to Fack MCP Server' }.to_json)
    
    # Keep connection alive and handle incoming messages
    loop do
      # In a real implementation, you'd read from a queue or websocket
      # For MCP over SSE, typically the client makes separate POST requests
      # and this stream just sends responses/events
      sleep 1
      sse_write.call('ping', { timestamp: Time.current.to_i }.to_json)
    end
  rescue IOError, ActionController::Live::ClientDisconnected
    # Client disconnected
  ensure
    response.stream.close rescue nil
  end

  # POST /mcp/message
  # Handle MCP JSON-RPC messages
  def message
    token = params[:token] || extract_bearer_token
    
    unless token && valid_token?(token)
      render json: { error: 'Invalid or missing token' }, status: :unauthorized
      return
    end
    
    @current_user = ApiToken.find_by(token: token, active: true)&.user
    
    begin
      request_data = JSON.parse(request.body.read)
      response_data = handle_mcp_request(request_data)
      render json: response_data
    rescue JSON::ParserError => e
      render json: { error: 'Invalid JSON', message: e.message }, status: :bad_request
    rescue StandardError => e
      render json: { error: 'Internal error', message: e.message }, status: :internal_server_error
    end
  end

  # GET /mcp/tools
  # Simple HTTP endpoint to list available tools (alternative to full MCP protocol)
  def tools
    authenticate_api_with_token
    
    render json: {
      tools: [
        {
          name: 'ask_question',
          description: 'Ask a question and get an AI-generated answer based on document libraries',
          inputSchema: {
            type: 'object',
            properties: {
              question: { type: 'string', description: 'The question to ask' },
              library_ids: { type: 'array', items: { type: 'number' }, description: 'Optional library IDs' }
            },
            required: ['question']
          }
        },
        {
          name: 'list_libraries',
          description: 'List all available document libraries',
          inputSchema: {
            type: 'object',
            properties: {
              page: { type: 'number', description: 'Page number' }
            }
          }
        },
        {
          name: 'search_documents',
          description: 'Search for documents',
          inputSchema: {
            type: 'object',
            properties: {
              query: { type: 'string', description: 'Search query' },
              library_id: { type: 'number', description: 'Optional library ID' }
            },
            required: ['query']
          }
        },
        {
          name: 'get_document',
          description: 'Get document by ID',
          inputSchema: {
            type: 'object',
            properties: {
              document_id: { type: 'number', description: 'Document ID' }
            },
            required: ['document_id']
          }
        }
      ]
    }
  end

  # POST /mcp/call
  # Simple HTTP endpoint to call tools (alternative to full MCP protocol)
  def call_tool
    authenticate_api_with_token
    
    tool_name = params[:tool] || params[:name]
    tool_args = params[:arguments] || params[:args] || {}
    
    result = execute_tool(tool_name, tool_args)
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def set_sse_headers
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
  end

  def sse_write
    @sse_write ||= proc do |event, data|
      response.stream.write("event: #{event}\n")
      response.stream.write("data: #{data}\n\n")
    end
  end

  def extract_bearer_token
    auth_header = request.headers['Authorization']
    return nil unless auth_header&.start_with?('Bearer ')
    auth_header.sub('Bearer ', '')
  end

  def valid_token?(token)
    ApiToken.exists?(token: token, active: true)
  end

  def handle_mcp_request(request_data)
    method = request_data['method']
    params = request_data['params'] || {}
    id = request_data['id']

    result = case method
             when 'tools/list'
               list_tools_mcp
             when 'tools/call'
               call_tool_mcp(params)
             else
               { error: "Unknown method: #{method}" }
             end

    {
      jsonrpc: '2.0',
      id: id,
      result: result
    }
  end

  def list_tools_mcp
    {
      tools: [
        {
          name: 'ask_question',
          description: 'Ask a question and get an AI-generated answer',
          inputSchema: {
            type: 'object',
            properties: {
              question: { type: 'string' },
              library_ids: { type: 'array', items: { type: 'number' } }
            },
            required: ['question']
          }
        },
        {
          name: 'list_libraries',
          description: 'List document libraries',
          inputSchema: { type: 'object', properties: {} }
        },
        {
          name: 'search_documents',
          description: 'Search documents',
          inputSchema: {
            type: 'object',
            properties: {
              query: { type: 'string' }
            },
            required: ['query']
          }
        },
        {
          name: 'get_document',
          description: 'Get document by ID',
          inputSchema: {
            type: 'object',
            properties: {
              document_id: { type: 'number' }
            },
            required: ['document_id']
          }
        }
      ]
    }
  end

  def call_tool_mcp(params)
    tool_name = params['name']
    arguments = params['arguments'] || {}
    
    result = execute_tool(tool_name, arguments)
    
    {
      content: [
        {
          type: 'text',
          text: result.to_json
        }
      ]
    }
  end

  def execute_tool(tool_name, arguments)
    case tool_name
    when 'ask_question'
      ask_question_tool(arguments)
    when 'list_libraries'
      list_libraries_tool(arguments)
    when 'search_documents'
      search_documents_tool(arguments)
    when 'get_document'
      get_document_tool(arguments)
    else
      raise "Unknown tool: #{tool_name}"
    end
  end

  def ask_question_tool(args)
    question = Question.create!(
      question: args['question'] || args[:question],
      library_ids_included: args['library_ids'] || args[:library_ids] || [],
      user: @current_user
    )
    
    # Wait for answer to be generated (simplified - in production use job polling)
    max_attempts = 30
    max_attempts.times do
      question.reload
      break if %w[generated failed].include?(question.status)
      sleep 2
    end
    
    {
      id: question.id,
      question: question.question,
      answer: question.answer,
      status: question.status,
      url: "#{ENV['ROOT_URL']}/questions/#{question.id}"
    }
  end

  def list_libraries_tool(args)
    page = args['page'] || args[:page] || 1
    libraries = Library.page(page).per(25)
    
    {
      libraries: libraries.map do |lib|
        {
          id: lib.id,
          name: lib.name,
          description: lib.description,
          documents_count: lib.documents_count
        }
      end
    }
  end

  def search_documents_tool(args)
    query = args['query'] || args[:query]
    library_id = args['library_id'] || args[:library_id]
    
    documents = Document.all
    documents = documents.where(library_id: library_id) if library_id
    documents = documents.search_by_title_and_document(query) if query.present?
    documents = documents.limit(25)
    
    {
      documents: documents.map do |doc|
        {
          id: doc.id,
          title: doc.title,
          library_id: doc.library_id,
          url: "#{ENV['ROOT_URL']}/documents/#{doc.id}"
        }
      end
    }
  end

  def get_document_tool(args)
    document_id = args['document_id'] || args[:document_id]
    document = Document.find(document_id)
    
    {
      id: document.id,
      title: document.title,
      document: document.document,
      library_id: document.library_id,
      url: "#{ENV['ROOT_URL']}/documents/#{document.id}"
    }
  end
end
