# frozen_string_literal: true

class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token
  def init
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(saml_settings), allow_other_host: true)
  end

  def lookup_or_create_user_by_email(email)
    user = User.find_by_email(email)
    return user if user

    if user.nil?
      # Create a user
      user = User.new(email:)
    end

    return nil unless user.save

    puts "Created user: #{user.email}"

    # Failed to create user

    user
  end

  def consume
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    request = OneLogin::RubySaml::Authrequest.new
    response.settings = saml_settings
    if response.is_valid?
      # Lookup user by email or create it
      email = response.name_id

      # TODO: Add more error handling
      user = lookup_or_create_user_by_email(email)

      # Setting the session logs the user in.  Need to make some methods for this.
      if user
        login_user(user)
      else
        notice = 'Login failed.  Please contact an admin for help.'
      end

      redirect_to root_path, notice:
    else
      redirect_to(request.create(saml_settings))
    end
  end

  def metadata
    settings = saml_settings
    meta = OneLogin::RubySaml::Metadata.new
    render xml: meta.generate(settings), content_type: 'application/samlmetadata+xml'
  end

  private

  def saml_settings
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    # Returns OneLogin::RubySaml::Settings pre-populated with IdP metadata
    # TODO - Cache This
    settings = idp_metadata_parser.parse_remote(ENV.fetch('SSO_METADATA_URL', nil))

    settings.assertion_consumer_service_url = "https://#{request.host}/auth/saml/consume"
    settings.sp_entity_id                   = "https://#{request.host}/auth/saml/metadata"

    settings
  end
end
