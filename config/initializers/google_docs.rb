require 'google/apis/docs_v1'
require 'googleauth'

# Authorize with Google using the service account
SCOPE = 'https://www.googleapis.com/auth/documents.readonly'
SERVICE_ACCOUNT_FILE = Rails.root.join('config/google_docs_service_account.json')

Google::Apis::RequestOptions.default.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(SERVICE_ACCOUNT_FILE),
  scope: SCOPE
)
