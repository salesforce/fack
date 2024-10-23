class SyncQuipDocJob < ApplicationJob
  queue_as :default

  def perform(_doc_id)
    begin
      document = Document.find(_doc_id)
    rescue ActiveRecord::RecordNotFound => e
      # Handle the case where the document is not found
      Rails.logger.error("Document with id #{_doc_id} not found: #{e.message}")
      return # Exit early since there's nothing to sync
    end

    # Log or handle cases where the document has no quip_url
    if document.source_url.blank?
      Rails.logger.warn("Document with id #{_doc_id} has no source URL.")
      return
    end

    begin
      # Initialize the Quip client
      quip_client = Quip::Client.new(access_token: ENV.fetch('QUIP_TOKEN'))
      uri = URI.parse(document.source_url)
      path = uri.path.sub(%r{^/}, '') # Removes the leading /
      quip_thread = quip_client.get_thread(path)

      # Convert Quip HTML content to Markdown
      markdown_quip = ReverseMarkdown.convert(quip_thread['html'])

      document.document = markdown_quip
      document.synced_at = DateTime.current
      document.last_sync_result = 'SUCCESS'
      document.save!
      # Reschedule the job to run again in 24 hours
      SyncQuipDocJob.set(wait: 24.hours, priority: 10).perform_later(_doc_id)
      return
    rescue ActiveRecord::RecordInvalid => e
      # Handle save! failures (validation errors)
      Rails.logger.error("Failed to save document with id #{_doc_id}: #{e.record.errors.full_messages.join(', ')}")
      document.document = "Document save failed: #{e.record.errors.full_messages.join(', ')}"
    rescue Quip::Error => e
      # Handle Quip-specific errors
      Rails.logger.error("Quip API error while fetching document from #{document.source_url}: #{e.message}")
      document.document = "Error from Quip: #{e.message}"
    rescue StandardError => e
      # Handle any other unforeseen errors
      Rails.logger.error("Unexpected error during sync for document id #{_doc_id}: #{e.message}")
      document.document = "#{e.message}"
    end

    document.last_sync_result = 'FAILED'
    document.save
    SyncQuipDocJob.set(wait: 30.minutes, priority: 10).perform_later(_doc_id)
  end
end
