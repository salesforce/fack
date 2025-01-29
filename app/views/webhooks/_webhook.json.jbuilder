json.extract! webhook, :id, :secret_key, :assistant_id, :type, :created_at, :updated_at
json.url webhook_url(webhook, format: :json)
