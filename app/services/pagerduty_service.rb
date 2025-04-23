require 'net/http'
require 'uri'
require 'json'
require 'date'

class PagerdutyService
  API_ENDPOINT = 'https://api.pagerduty.com/incidents'

  class Error < StandardError; end

  def initialize
    @api_token = ENV.fetch('PAGERDUTY_API_TOKEN', nil)
    raise Error, 'PAGERDUTY_API_TOKEN environment variable not set.' unless @api_token
  end

  # Fetch incidents from the last X hours
  # @param hours [Integer] Number of hours to look back
  # @param statuses [Array<String>] Optional array of statuses to filter by (triggered, acknowledged, resolved)
  # @return [Array<Pagerduty::Response>] Array of incident objects
  def get_recent_incidents(hours: 24, statuses: %w[triggered acknowledged])
    incidents_by_service = {}
    more = true
    offset = 0
    limit = 100
    end_time = Time.now.utc
    start_time = end_time - hours.hours

    while more
      uri = URI(API_ENDPOINT)
      params = {
        'since' => start_time.iso8601,
        'until' => end_time.iso8601,
        'limit' => limit.to_s,
        'offset' => offset.to_s,
        'include[]' => %w[services teams],
        'statuses[]' => statuses
      }
      uri.query = URI.encode_www_form(params)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri)
      request['Authorization'] = "Token token=#{@api_token}"
      request['Accept'] = 'application/vnd.pagerduty+json;version=2'

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("[PagerDuty Error] HTTP request failed with status #{response.code}")
        Rails.logger.error(response.body)
        raise Error, "HTTP request failed with status #{response.code}"
      end

      begin
        json_response = JSON.parse(response.body)
      rescue JSON::ParserError
        Rails.logger.error('[PagerDuty Error] Failed to parse JSON response')
        Rails.logger.error(response.body)
        raise Error, 'Failed to parse JSON response'
      end

      raise Error, "PagerDuty API Error: #{json_response['error']['message']}" if json_response.key?('error')

      incidents = json_response['incidents'] || []

      incidents.each do |incident|
        service_name = incident.dig('service', 'summary') || 'N/A'
        incidents_by_service[service_name] ||= []
        incidents_by_service[service_name] << {
          number: incident['incident_number'],
          status: incident['status'],
          team: incident.dig('team', 'summary') || 'N/A',
          problem: incident['summary'],
          date: DateTime.iso8601(incident['created_at']).strftime('%m/%d/%y %H:%M:%S')
        }
      end

      offset += limit
      more = json_response['more']

      # Basic rate limiting
      sleep 1

      # Stop if we've gone past our time window
      if incidents.any? && DateTime.iso8601(incidents.last['created_at']) < DateTime.iso8601(start_time.iso8601)
        Rails.logger.info('Finished processing incidents within the time window.')
        more = false
      end
    end

    incidents_by_service
  end
end
