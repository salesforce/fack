# frozen_string_literal: true

json.extract! chat, :id, :chat, :created_at, :updated_at
json.url assistant_url(chat)
