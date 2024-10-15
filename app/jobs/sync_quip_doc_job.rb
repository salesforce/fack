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
      document.save
    rescue Quip::Error => e
      # Handle Quip-specific errors
      Rails.logger.error("Quip API error while fetching document from #{document.source_url}: #{e.message}")
      document.last_sync_result = "#{e.message}"
      document.save
    rescue StandardError => e
      # Handle any other unforeseen errors
      Rails.logger.error("Unexpected error during sync for document id #{_doc_id}: #{e.message}")
      document.last_sync_result = "#{e.message}"
      document.save
    end

    # Reschedule the job to run again in 24 hours
    SyncQuipDocJob.set(wait: 24.hours).perform_later(_doc_id)
  end
end
