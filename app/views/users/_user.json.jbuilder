# frozen_string_literal: true

json.extract! user, :id, :email, :created_at, :updated_at
json.url user_url(user, format: :json)
