class Api::V1::DocumentsController < BaseDocumentsController
  skip_before_action :verify_authenticity_token
end
