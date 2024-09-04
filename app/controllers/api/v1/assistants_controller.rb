# frozen_string_literal: true

module Api
  module V1
    class AssistantsController < BaseAssistantsController
      skip_before_action :verify_authenticity_token, only: :create
    end
  end
end
