# frozen_string_literal: true

# Configure CORS for Chrome extension and MCP support
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow Chrome extensions (chrome-extension://) and development origins
    origins(/chrome-extension:\/\/.*/, 'http://localhost:3000', 'https://localhost:3000')
    
    resource '/api/*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             credentials: false
  end

  # MCP (Model Context Protocol) endpoints - allow from anywhere
  allow do
    origins '*'
    
    resource '/mcp/*',
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             expose: ['Content-Type', 'Cache-Control', 'X-Accel-Buffering'],
             credentials: false
  end

  # For production, you might want to be more specific about allowed origins
  # allow do
  #   origins 'chrome-extension://your-extension-id-here'
  #   resource '/api/*',
  #            headers: :any,
  #            methods: [:get, :post, :put, :patch, :delete, :options, :head],
  #            credentials: false
  # end
end
