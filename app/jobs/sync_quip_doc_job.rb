class SyncQuipDocJob < ApplicationJob
  queue_as :default

  def perform(_doc_id)
    document = fetch_document(_doc_id)
    return unless document

    if document.source_url.blank?
      log_warning("Document with id #{_doc_id} has no source URL.")
      return
    end

    success = sync_document_with_quip(document)
    update_sync_status(document, success:)
    schedule_next_sync(document.id, success:)
  end

  private

  def fetch_document(doc_id)
    Document.find(doc_id)
  rescue ActiveRecord::RecordNotFound => e
    log_error("Document with id #{doc_id} not found: #{e.message}")
    nil
  end

  def sync_document_with_quip(document)
    quip_client = initialize_quip_client
    quip_thread = fetch_quip_thread(document.source_url, quip_client)
    return false unless quip_thread

    update_document_from_quip(document, quip_thread)
    true
  rescue ActiveRecord::RecordInvalid => e
    handle_save_error(document, e)
    false
  rescue Quip::Error => e
    handle_quip_error(document, e)
    false
  rescue StandardError => e
    handle_unexpected_error(document, e)
    false
  end

  def initialize_quip_client
    Quip::Client.new(access_token: ENV.fetch('QUIP_TOKEN'))
  end

  def fetch_quip_thread(source_url, quip_client)
    uri = URI.parse(source_url)
    path = uri.path.sub(%r{^/}, '')
    quip_client.get_thread(path)
  rescue Quip::Error => e
    log_error("Quip API error while fetching document from #{source_url}: #{e.message}")
    nil
  end

  def update_document_from_quip(document, quip_thread)
    markdown_quip = ReverseMarkdown.convert(quip_thread['html'])
    document.update!(document: markdown_quip, synced_at: DateTime.current, last_sync_result: 'SUCCESS')
  end

  def handle_save_error(document, exception)
    log_error("Failed to save document with id #{document.id}: #{exception.record.errors.full_messages.join(', ')}")
    document.update(document: "Document save failed: #{exception.record.errors.full_messages.join(', ')}")
  end

  def handle_quip_error(document, exception)
    log_error("Quip API error for document id #{document.id}: #{exception.message}")
    document.update(document: "Error from Quip: #{exception.message}")
  end

  def handle_unexpected_error(document, exception)
    log_error("Unexpected error during sync for document id #{document.id}: #{exception.message}")
    document.update(document: exception.message)
  end

  def update_sync_status(document, success:)
    document.update(synced_at: DateTime.current, last_sync_result: success ? 'SUCCESS' : 'FAILED')
  end

  def schedule_next_sync(doc_id, success:)
    delay = success ? 24.hours : 3.hours
    SyncQuipDocJob.set(wait: delay, priority: 10).perform_later(doc_id)
  end

  def log_error(message)
    Rails.logger.error(message)
  end

  def log_warning(message)
    Rails.logger.warn(message)
  end
end
