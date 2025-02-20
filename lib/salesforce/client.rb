require 'savon'
require 'restforce'
require 'logger'

module Salesforce
  class Client
    SF_LOGIN_URL = ENV.fetch('SF_LOGIN_URL', nil)

    attr_reader :session_id, :instance_url, :restforce_client

    def initialize(username: ENV.fetch('SF_USERNAME', nil), password: ENV.fetch('SF_PASSWORD', nil))
      @username = username
      @password = password

      raise 'Salesforce credentials missing' if @username.nil? || @password.nil?

      setup_logger
      authenticate
    end

    private

    def setup_logger
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::ERROR
    end

    def authenticate
      savon_client = Savon.client(
        endpoint: SF_LOGIN_URL + '/services/Soap/u/63.0',
        namespace: 'urn:partner.soap.sforce.com',
        ssl_verify_mode: :none
      )

      response = savon_client.call(:login, xml: soap_request_body)

      login_result = response.body[:login_response][:result]
      @session_id = login_result[:session_id]
      @instance_url = extract_instance_url(login_result[:server_url])

      @logger.info '🎉 Salesforce login successful!'
      @logger.info "Instance URL: #{@instance_url}"

      initialize_restforce
    end

    def soap_request_body
      <<~XML
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
          xmlns:xsd="http://www.w3.org/2001/XMLSchema"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <soapenv:Body>
            <login xmlns="urn:partner.soap.sforce.com">
              <username>#{@username}</username>
              <password>#{@password}</password>
            </login>
          </soapenv:Body>
        </soapenv:Envelope>
      XML
    end

    def extract_instance_url(server_url)
      server_url.match(%r{https://([^/]+)})[0]
    end

    def initialize_restforce
      @restforce_client = Restforce.new(
        instance_url: @instance_url,
        oauth_token: @session_id,
        authentication_middleware: Restforce::Middleware::Authentication::Token
      )
    end

    public

    def fetch_user_info
      @restforce_client.get('/services/data/v63.0/chatter/users/me').body
    rescue Restforce::UnauthorizedError => e
      @logger.error "Salesforce authentication error: #{e.message}"
      nil
    end

    def query(soql)
      @restforce_client.query(soql)
    rescue StandardError => e
      @logger.error "Salesforce query error: #{e.message}"
      nil
    end
  end
end
