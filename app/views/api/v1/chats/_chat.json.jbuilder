# frozen_string_literal: true

json.extract! chat, :id, :created_at, :updated_at, :first_message, :user_id

# Include URL
json.url assistant_url(chat)

# Include all the messages associated with the chat
json.messages chat.messages do |message|
  json.extract! message, :id, :content, :created_at, :user_id, :status, :from
end
