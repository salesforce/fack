#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using the CLI token to make authenticated API calls
# This demonstrates how to read the token from ~/.fack/credentials
# and use it to make authenticated requests to the FACK API

require 'json'
require 'net/http'
require 'uri'

# Read credentials
CREDENTIALS_PATH = File.expand_path('~/.fack/credentials')

unless File.exist?(CREDENTIALS_PATH)
  puts "❌ No credentials found at #{CREDENTIALS_PATH}"
  puts ""
  puts "Please run: ruby scripts/cli_login.rb"
  exit 1
end

credentials = JSON.parse(File.read(CREDENTIALS_PATH))
token = credentials['token']
host = credentials['host'] || 'http://localhost:3000'

puts "🔑 Using token from: #{CREDENTIALS_PATH}"
puts "🌐 API host: #{host}"
puts ""

# Example 1: List libraries
puts "📚 Fetching libraries..."
uri = URI("#{host}/api/v1/libraries")
request = Net::HTTP::Get.new(uri)
request['Authorization'] = "Bearer #{token}"
request['Content-Type'] = 'application/json'

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
  http.request(request)
end

if response.is_a?(Net::HTTPSuccess)
  libraries = JSON.parse(response.body)
  puts "✅ Found #{libraries.length} libraries:"
  libraries.each do |lib|
    puts "  - #{lib['name']} (ID: #{lib['id']})"
  end
else
  puts "❌ Error: #{response.code} #{response.message}"
  puts response.body
end

puts ""

# Example 2: List documents
puts "📄 Fetching documents..."
uri = URI("#{host}/api/v1/documents")
request = Net::HTTP::Get.new(uri)
request['Authorization'] = "Bearer #{token}"
request['Content-Type'] = 'application/json'

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
  http.request(request)
end

if response.is_a?(Net::HTTPSuccess)
  documents = JSON.parse(response.body)
  puts "✅ Found #{documents.length} documents"
else
  puts "❌ Error: #{response.code} #{response.message}"
end

puts ""
puts "✨ Done!"
