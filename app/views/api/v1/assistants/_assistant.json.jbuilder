# frozen_string_literal: true

json.extract! assistant, :id, :assistant, :name, :created_at, :updated_at, :status
json.url assistant_url(assistant)
