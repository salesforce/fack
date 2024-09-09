# frozen_string_literal: true

json.extract! message, :id, :content, :created_at, :user_id, :status, :from

# Include URL
json.url message_url(message)
