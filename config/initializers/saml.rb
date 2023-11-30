Rails.application.config.saml_settings = {
    assertion_consumer_service_url: "http://localhost:3000/auth/saml/callback",
    issuer: "fack",
    idp_entity_id: "identity-provider-entity-id",
    idp_sso_target_url: "identity-provider-sso-url",
    idp_cert: "-----BEGIN CERTIFICATE-----\n...identity provider certificate...\n-----END CERTIFICATE-----"
  }
  