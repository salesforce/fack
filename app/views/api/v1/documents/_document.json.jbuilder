# frozen_string_literal: true

json.extract! document, :id, :document, :title, :url, :length, :created_at, :updated_at, :enabled
json.url document_url(document)
