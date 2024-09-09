module Api
  module V1
    class MessagesController < BaseMessagesController
      skip_before_action :verify_authenticity_token, only: :create
    end
  end
end
