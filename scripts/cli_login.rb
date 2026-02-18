#!/usr/bin/env ruby
# frozen_string_literal: true

# CLI Authentication Script
# Usage: ruby scripts/cli_login.rb [--host https://yourapp.com] [--port 9090]
#
# This script will:
# 1. Start a temporary HTTP server on localhost
# 2. Open your browser to authorize the CLI
# 3. Receive the token via redirect
# 4. Save the token to ~/.fack/credentials

require 'webrick'
require 'securerandom'
require 'fileutils'
require 'json'
require 'optparse'

class CliLogin
  DEFAULT_HOST = ENV['FACK_HOST'] || 'http://localhost:3000'
  DEFAULT_PORT = 9090
  CREDENTIALS_PATH = File.expand_path('~/.fack/credentials')

  def initialize(host: DEFAULT_HOST, port: DEFAULT_PORT)
    @host = host
    @port = port
    @state = SecureRandom.hex(32)
    @token = nil
  end

  def run
    puts '🔐 FACK CLI Authentication'
    puts '=' * 50
    puts ''

    # Start server in a thread
    server_thread = Thread.new { start_server }

    # Give server a moment to start
    sleep 0.5

    # Open browser
    open_browser

    # Wait for server to receive token
    server_thread.join

    if @token
      save_token
      puts ''
      puts '✅ Success! You are now authenticated.'
      puts ''
      puts "Your token has been saved to: #{CREDENTIALS_PATH}"
      puts ''
      puts 'You can now use the FACK CLI tools.'
      exit 0
    else
      puts ''
      puts '❌ Authentication failed or timed out.'
      puts ''
      puts 'Please try again or contact support.'
      exit 1
    end
  end

  private

  def start_server
    server = WEBrick::HTTPServer.new(
      Port: @port,
      Logger: WEBrick::Log.new('/dev/null'),
      AccessLog: []
    )

    server.mount_proc '/callback' do |req, res|
      # Validate state parameter
      if req.query['state'] != @state
        res.status = 400
        res.body = error_page('Invalid state parameter')
        next
      end

      # Get token
      @token = req.query['token']

      if @token
        res.status = 200
        res.content_type = 'text/html'
        res.body = success_page
      else
        res.status = 400
        res.body = error_page('No token received')
      end

      # Shutdown server after response
      Thread.new do
        sleep 0.5
        server.shutdown
      end
    end

    # Set a timeout
    timeout_thread = Thread.new do
      sleep 120 # 2 minute timeout
      puts "\n⏱️  Authentication timed out."
      server.shutdown unless @token
    end

    begin
      server.start
    rescue StandardError => e
      puts "❌ Error starting server: #{e.message}"
      exit 1
    ensure
      timeout_thread.kill if timeout_thread.alive?
    end
  end

  def open_browser
    auth_url = "#{@host}/cli/authorize?state=#{@state}&port=#{@port}"

    puts 'Opening browser to authorize...'
    puts ''
    puts "If your browser doesn't open automatically, visit:"
    puts auth_url
    puts ''

    case RbConfig::CONFIG['host_os']
    when /darwin/
      system('open', auth_url)
    when /linux/
      system('xdg-open', auth_url)
    when /mswin|mingw|cygwin/
      system('start', auth_url)
    else
      puts '⚠️  Could not detect your OS. Please open the URL above manually.'
    end
  end

  def save_token
    # Create directory if it doesn't exist
    dir = File.dirname(CREDENTIALS_PATH)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)

    # Save token as JSON
    credentials = {
      token: @token,
      host: @host,
      created_at: Time.now.iso8601
    }

    File.write(CREDENTIALS_PATH, JSON.pretty_generate(credentials))

    # Set file permissions to user-only
    File.chmod(0o600, CREDENTIALS_PATH)
  end

  def success_page
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Authentication Successful</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          }
          .container {
            background: white;
            padding: 3rem;
            border-radius: 1rem;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 400px;
          }
          .success-icon {
            font-size: 4rem;
            margin-bottom: 1rem;
          }
          h1 {
            color: #10b981;
            margin-bottom: 0.5rem;
          }
          p {
            color: #6b7280;
            line-height: 1.6;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="success-icon">✅</div>
          <h1>Success!</h1>
          <p>You are now authenticated with FACK CLI.</p>
          <p><strong>You can close this window.</strong></p>
        </div>
      </body>
      </html>
    HTML
  end

  def error_page(message)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Authentication Error</title>
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
          }
          .container {
            background: white;
            padding: 3rem;
            border-radius: 1rem;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            text-align: center;
            max-width: 400px;
          }
          .error-icon {
            font-size: 4rem;
            margin-bottom: 1rem;
          }
          h1 {
            color: #ef4444;
            margin-bottom: 0.5rem;
          }
          p {
            color: #6b7280;
            line-height: 1.6;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="error-icon">❌</div>
          <h1>Error</h1>
          <p>#{message}</p>
          <p>Please try again.</p>
        </div>
      </body>
      </html>
    HTML
  end
end

# Parse command line options
options = {
  host: CliLogin::DEFAULT_HOST,
  port: CliLogin::DEFAULT_PORT
}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby cli_login.rb [options]'

  opts.on('-h', '--host HOST', 'Server host (default: http://localhost:3000 or $FACK_HOST)') do |h|
    options[:host] = h
  end

  opts.on('-p', '--port PORT', Integer, 'Local port for callback (default: 9090)') do |p|
    options[:port] = p
  end

  opts.on('--help', 'Show this help message') do
    puts opts
    exit
  end
end.parse!

# Run the CLI login
CliLogin.new(host: options[:host], port: options[:port]).run
