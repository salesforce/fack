require 'net/http'
require 'json'
require 'optparse'
require 'digest'


# Define the API endpoint URL
options = {}
required_options = %i[url library_id directory_path token]
opt_parser = OptionParser.new do |opts|
  opts.banner = 'Usage: import.sh [options]'

  opts.on('-u', '--url URL', 'Base url of Fack server (required)') do |value|
    options[:url] = value
  end

  opts.on('-l', '--library ID', 'Library id which contains documents (required)') do |value|
    options[:library_id] = value
  end

  opts.on('-d', '--directory DIR', 'Directory path of docs to import (required)') do |value|
    options[:directory_path] = value
  end

  opts.on('-t', '--token TOKEN', 'Provide an Auth Token (required)') do |value|
    options[:token] = value
  end
end

begin
  opt_parser.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts opt_parser
  exit 1
end

# Check if all required options are present
missing_options = required_options.select { |opt| options[opt].nil? }

# Output the result
unless missing_options.empty?
  puts "\nERROR: missing required options: #{missing_options.join(', ')}\n\n"
  puts opt_parser
  exit 1
end

api_url = URI.parse(options[:url] + '/api/v1/documents')
directory_path = options[:directory_path]
library_id = options[:library_id]
auth_token = options[:token]

# Check if the directory path is provided
if directory_path.nil? || library_id.nil?
  puts 'Usage: ruby script.rb /path/to/your/files library_id'
  exit(1)
end

def process_directory(directory_path, library_id, api_url, headers)
  Dir.foreach(directory_path) do |file_name|
    next if file_name == '.' || file_name == '..' || file_name.start_with?('.') # Skip special and hidden entries

    file_path = File.join(directory_path, file_name)

    if File.directory?(file_path)
      # If it's a directory, recursively process it
      process_directory(file_path, library_id, api_url, headers)
    elsif file_name.end_with?('md') || file_name.end_with?('mdx')
      puts "\n# Processing: " + file_path

      # Read the content of the file
      file_content = File.read(file_path)

      # Create a hash with the file content
      external_id = Digest::MD5.hexdigest(File.expand_path(file_path))
      document_data = {
        document: {
          document: file_content.force_encoding('ISO-8859-1').encode('UTF-8'),
          title: file_name,
          external_id: ,
          library_id:
        }
      }

      # Create an HTTP object and set up the request
      http = Net::HTTP.new(api_url.host, api_url.port)
      if api_url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Post.new(api_url.path, headers)

      # Convert the document_data hash to JSON
      request.body = document_data.to_json

      # Send the POST request to create the new document
      response = http.request(request)

      # Check the response status code
      if response.code.to_i == 201
        puts "Document '#{file_path}' uploaded successfully."
      else
        puts "Failed to create document '#{file_path}'. Error message: #{response.body[0..20_000]}"
      end
    end
  end
end

# Define the directory path, API URL, and headers
headers = { 'Content-Type' => 'application/json', 'Authorization' => 'Bearer ' + auth_token }

# Start processing the directory and its subdirectories

process_directory(directory_path, library_id, api_url, headers)
