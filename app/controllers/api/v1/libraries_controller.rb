# frozen_string_literal: true

module Api
  module V1
    class LibrariesController < BaseLibrariesController
      skip_before_action :verify_authenticity_token, only: %i[create update]
    end
  end
end
