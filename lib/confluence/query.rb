require 'net/http'
require 'uri'
require 'json'
require 'cgi'

module Confluence
  class Query
    def initialize
      # @target_env = ENV.fetch('TARGET_ENV', nil)
      @confluence_token = ENV.fetch('CONFLUENCE_TOKEN', nil)
    end

    def query_confluence(spaces = nil, query)
      url = base_url
      cql = build_cql(spaces, query)
      encoded_cql = CGI.escape(cql)

      uri = URI.parse(url + encoded_cql + '&expand=content.body.view,content.metadata.labels,content.children.comment')

      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{@confluence_token}"

      response = send_request(uri, request)
      JSON.parse(response.body)
    end

    private

    def base_url
      ENV.fetch('CONFLUENCE_URL', nil)
    end

    def build_cql(spaces, query)
      cql = "(type = 'page' AND "

      # Format spaces if provided
      if spaces && !spaces.empty?
        formatted_spaces = spaces.split(',').map { |space| "\"#{space.strip}\"" }.join(',')
        cql += "space in (#{formatted_spaces}) AND "
      end

      # Add the query
      cql += "siteSearch ~ \"#{query}\")"
      cql
    end

    def send_request(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      http.request(request)
    end
  end
end
