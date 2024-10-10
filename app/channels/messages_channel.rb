class MessagesChannel < ApplicationCable::Channel
  def subscribed
    token = params[:token]

    if token.present? && authenticate_token(token)
      stream_from 'messages_channel'
      Rails.logger.info "User #{connection.current_user.id} subscribed to MessagesChannel."
    else
      reject
    end
  end

  def unsubscribed
    # Log the event when the user unsubscribes
    if connection.current_user
      Rails.logger.info "User #{connection.current_user.id} unsubscribed from MessagesChannel."
    else
      Rails.logger.info 'A user unsubscribed from MessagesChannel, but no user was identified.'
    end
  end

  private

  def authenticate_token(token)
    current_api_token = ApiToken.find_by(token:, active: true)

    if current_api_token
      connection.current_user = current_api_token.user
      current_api_token.update!(last_used: DateTime.now)
    end

    connection.current_user.present?
  end
end
