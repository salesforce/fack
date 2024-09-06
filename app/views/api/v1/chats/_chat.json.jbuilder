# frozen_string_literal: true

json.extract! chat, :id, :created_at, :updated_at
json.url assistant_url(chat)
