require 'net/http'
require 'uri'
require 'json'

module Quip
  class Error < StandardError; end

  class Client
    APPEND = 0
    PREPEND = 1
    AFTER_SECTION = 2
    BEFORE_SECTION = 3
    REPLACE_SECTION = 4
    DELETE_SECTION = 5

    MANILA = 0
    RED = 1
    ORANGE = 2
    GREEN = 3
    BLUE = 4

    attr_accessor :access_token, :client_id, :client_secret, :base_url, :request_timeout

    def initialize(access_token: nil, client_id: nil, client_secret: nil, base_url: 'https://platform.quip.com', request_timeout: 10)
      @access_token = access_token
      @client_id = client_id
      @client_secret = client_secret
      @base_url = base_url
      @request_timeout = request_timeout
    end

    def get_authorization_url(redirect_uri, state = nil)
      url = URI.join(@base_url, 'oauth/login')
      params = {
        redirect_uri:,
        state:,
        response_type: 'code',
        client_id: @client_id
      }
      url.query = URI.encode_www_form(params)
      url.to_s
    end

    def get_access_token(redirect_uri, code, grant_type = 'authorization_code', refresh_token = nil)
      post_request('oauth/access_token', {
                     redirect_uri:,
                     code:,
                     grant_type:,
                     refresh_token:,
                     client_id: @client_id,
                     client_secret: @client_secret
                   })
    end

    def get_authenticated_user
      get_request('users/current')
    end

    def get_user(id)
      get_request("users/#{id}")
    end

    def get_users(ids)
      post_request('users/', { ids: ids.join(',') })
    end

    def update_user(user_id, picture_url: nil)
      post_request('users/update', {
                     user_id:,
                     picture_url:
                   })
    end

    # Fetches a single thread by its ID
    def get_thread(id)
      get_request("threads/#{id}/html")
    end

    # Fetches multiple threads by their IDs
    def get_threads(ids)
      post_request('threads/', { ids: ids.join(',') })
    end

    # Fetches recent threads, optionally with additional parameters
    def get_recent_threads(max_updated_usec: nil, count: nil, **kwargs)
      params = { max_updated_usec:, count: }.merge(kwargs)
      get_request('threads/recent', params)
    end

    # Searches for threads matching the given query
    def get_matching_threads(query, count: nil, only_match_titles: false, **kwargs)
      params = { query:, count:, only_match_titles: }.merge(kwargs)
      get_request('threads/search', params)
    end

    private

    def get_request(path, params = {})
      uri = URI.join(@base_url, "/2/#{path}")
      uri.query = URI.encode_www_form(clean_params(params))
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{@access_token}" if @access_token
      execute_request(uri, request)
    end

    def post_request(path, post_data = {})
      uri = URI.join(@base_url, "/2/#{path}")
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@access_token}" if @access_token
      request.set_form_data(clean_params(post_data))
      execute_request(uri, request)
    end

    def clean_params(params)
      params.reject { |_, v| v.nil? || v == '' }
    end

    def execute_request(uri, request)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.read_timeout = @request_timeout
        http.request(request)
      end

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      else
        message = begin
          JSON.parse(response.body)['error_description']
        rescue StandardError
          response.message
        end
        raise Error.new("#{response.code}: #{message}")
      end
    end
  end
end
