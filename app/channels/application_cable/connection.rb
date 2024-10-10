# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      # We don't need to fetch `identifier` here as we're going to do that in the channel
      self.current_user = nil # Will be set during the subscription in the channel
    end
  end
end
