# frozen_string_literal: true

json.extract! chat, :id, :created_at, :updated_at, :first_message, :user_id
json.url assistant_url(chat)
