# frozen_string_literal: true

json.extract! library, :id, :name, :created_at, :updated_at
json.url library_url(library)
