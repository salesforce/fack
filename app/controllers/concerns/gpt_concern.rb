# frozen_string_literal: true

require 'net/http'
require 'httparty'
require 'uri'
require 'json'

module GptConcern
  extend ActiveSupport::Concern

  # Helper to make secure prompts
  def replace_tag_with_random(input_string, tag)
    random_string = SecureRandom.hex(10)
    input_string.gsub(tag) { random_string }
  end

  def get_embedding(input)
    if ENV['OPENAI_API_KEY'].present?
      call_openai_embedding(input)
    else
      call_salesforce_connect_gpt_embedding(input)
    end
  end

  def get_generation(prompt)
    if ENV['OPENAI_API_KEY'].present?
      call_openai_generation(prompt)
    else
      call_salesforce_connect_gpt_generation(prompt)
    end
  end

  def call_openai_embedding(input)
    access_token = ENV.fetch('OPENAI_API_KEY', nil)
    endpoint_url = 'https://api.openai.com/v1/embeddings'
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
    body = {
      input:,
      model: 'text-embedding-ada-002',
      encoding_format: 'float'
    }

    response = HTTParty.post(endpoint_url, body: body.to_json, headers:)
    if response.code == 200
      JSON.parse(response.body)
      response_data = JSON.parse(response.body)
      response_data['data'][0]['embedding']
    else
      # Handle error
      puts "Error calling OpenAI API for embeddings: #{response.code} - #{response.message}"
      nil
    end
  end

  def call_openai_generation(prompt)
    access_token = ENV.fetch('OPENAI_API_KEY', nil)
    endpoint_url = 'https://api.openai.com/v1/chat/completions'
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }
    body = {
      messages: [
        { role: 'user', content: prompt }
      ],
      model: ENV['EGPT_GEN_MODEL'] || 'gpt-3.5-turbo-16k'
      # Add additional parameters as required by OpenAI
    }

    response = HTTParty.post(endpoint_url, body: body.to_json, headers:)
    return JSON.parse(response.body)['choices'].first['message']['content'] if response.code == 200

    # Handle error
    puts "Error calling OpenAI API for generation: #{response.code} - #{response.message}"
    ''
  end

  def call_salesforce_connect_gpt_embedding(input)
    oauth_token = get_salesforce_connect_oauth_token
    access_token = oauth_token['access_token']
    instance_url = oauth_token['instance_url']

    new_endpoint_url = "#{instance_url}/services/data/v58.0/einstein/llm/embeddings"
    request_body = {
      prompts: { wrappedListString: [input] },
      additionalConfig: {
        applicationName: 'fack'
      }
    }

    uri = URI.parse(new_endpoint_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path)
    request.body = request_body.to_json
    request['Authorization'] = "Bearer #{access_token}"
    request['Content-Type'] = 'application/json'

    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      response_data = JSON.parse(response.body)
      return response_data['embeddings'][0]['embedding']
    else
      Rails.logger.error("Error calling Salesforce Connect GPT: #{response.body.message}")
    end

    null
  end

  def call_salesforce_connect_gpt_generation(prompt)
    begin
      oauth_token = get_salesforce_connect_oauth_token
      access_token = oauth_token['access_token']
      instance_url = oauth_token['instance_url']

      new_endpoint_url = "#{instance_url}/services/data/v58.0/einstein/llm/prompt/generations"
      prompt_text_or_id = prompt
      request_body = {
        promptTextorId: prompt_text_or_id,
        provider: 'OpenAI',
        additionalConfig: {
          applicationName: 'fack',
          maxTokens: ENV['EGPT_MAX_TOKENS'] || 3000, # roughly one page worth of an answer
          model: ENV['EGPT_GEN_MODEL'] || 'gpt-4-32k',
          temperature: 0.3,
          numGenerations: 1
        }
      }

      response = HTTParty.post(new_endpoint_url, body: request_body.to_json, headers: {
                                 'Authorization' => "Bearer #{access_token}",
                                 'Content-Type' => 'application/json'
                               })

      response_data = JSON.parse(response.body)

      # Decode the HTML entities
      decoded_text = CGI.unescapeHTML(response_data['generations'][0]['text'])

      return decoded_text
    rescue StandardError => e
      Rails.logger.error("Error calling Salesforce Connect GPT: #{e.message}")
    end

    ''
  end

  private

  def get_salesforce_connect_oauth_token
    encoded_client_id = URI.encode_www_form_component(ENV['SALESFORCE_CONNECT_CLIENT_ID'] || '')
    encoded_client_secret = URI.encode_www_form_component(ENV['SALESFORCE_CONNECT_CLIENT_SECRET'] || '')
    encoded_username = ENV.fetch('SALESFORCE_CONNECT_USERNAME', nil)
    encoded_password = ENV.fetch('SALESFORCE_CONNECT_PASSWORD', nil)

    token_request_data = {
      grant_type: 'password',
      client_id: encoded_client_id,
      client_secret: encoded_client_secret,
      username: encoded_username,
      password: encoded_password
    }

    URI.encode_www_form(token_request_data)
    oauth_url = "#{ENV.fetch('SALESFORCE_CONNECT_ORG_URL', nil)}/services/oauth2/token"

    begin
      uri = URI.parse(oauth_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
      request.set_form_data(token_request_data)
      request['Content-Type'] = 'application/x-www-form-urlencoded'

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        access_token = JSON.parse(response.body)
        return access_token
      else
        puts "Error calling Salesforce Connect OAuth: #{response.code} - #{response.body}"
      end
    rescue StandardError => e
      puts "Error calling Salesforce Connect OAuth: #{e.message}"
    end

    nil
  end
end
