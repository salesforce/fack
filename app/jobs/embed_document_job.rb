# frozen_string_literal: true

class EmbedDocumentJob < ApplicationJob
  include SalesforceGptConcern # Include the concern here

  queue_as :default

  def perform(document_id)
    document = Document.find(document_id)
    begin
      document.update(embedding: get_embedding(document.document))
    rescue StandardError
      Rails.logger.error('Error calling Salesforce Connect GPT.')
    end
  end
end
