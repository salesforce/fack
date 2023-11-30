class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token
  def init
    request = OneLogin::RubySaml::Authrequest.new
    redirect_to(request.create(saml_settings))
  end

  def consume
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse])
    request = OneLogin::RubySaml::Authrequest.new
    response.settings = saml_settings
    if response.is_valid?
      session[:authenticated] = true
      redirect_to root_path
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
    settings = OneLogin::RubySaml::Settings.new

    settings.assertion_consumer_service_url = "http://#{request.host}/saml/consume"
    settings.sp_entity_id                   = "http://#{request.host}/saml/metadata"
    settings.idp_sso_service_url = "https://app.onelogin.com/saml/signon/"
    #settings.idp_cert_fingerprint           = OneLoginAppCertFingerPrint
    settings.name_identifier_format         = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'

    # Optional for most SAML IdPs
    settings.authn_context = 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport'

    # Optional. Describe according to IdP specification (if supported) which attributes the SP desires to receive in SAMLResponse.
    settings.attributes_index = 5
    # Optional. Describe an attribute consuming service for support of additional attributes.
    settings.attribute_consuming_service.configure do
      service_name 'Service'
      service_index 5
      add_attribute name: 'Name', name_format: 'Name Format', friendly_name: 'Friendly Name'
    end

    settings
  end
end
