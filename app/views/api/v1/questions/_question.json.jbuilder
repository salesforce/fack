json.extract! question, :id, :question, :answer, :created_at, :updated_at, :status, :able_to_answer,
              :slack_markdown_answer, :source_url, :library_ids_included
json.url question_url(question)
