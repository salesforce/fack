# frozen_string_literal: true

module Api
  module V1
    class QuestionsController < BaseQuestionsController
      skip_before_action :verify_authenticity_token, only: :create
    end
  end
end
