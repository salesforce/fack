json.extract! assistant, :id, :user_prompt, :llm_prompt, :libraries, :created_at, :updated_at
json.url assistant_url(assistant, format: :json)
