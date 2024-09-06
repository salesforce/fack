# frozen_string_literal: true

json.extract! assistant, :id, :name, :libraries, :input, :output, :instructions, :context, :description, :created_at, :updated_at, :status, :quip_url, :confluence_spaces
json.url assistant_url(assistant)
