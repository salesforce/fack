class Api::V1::LibrariesController < BaseLibrariesController
  skip_before_action :verify_authenticity_token, only: :create
end
