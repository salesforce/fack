class Api::V1::QuestionsController < BaseQuestionsController
  skip_before_action :verify_authenticity_token, only: :create
end
