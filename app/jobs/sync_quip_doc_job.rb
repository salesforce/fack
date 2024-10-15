class SyncQuipDocJob < ApplicationJob
  queue_as :default

  def perform(_doc_id)
    document = Document.find(_doc_id)
    # Your logic here
    puts document.title

    # QUIP Doc
    # return unless document.quip_url.present?
    quip_url = document.source_url

    quip_client = Quip::Client.new(access_token: ENV.fetch('QUIP_TOKEN'))

    uri = URI.parse(quip_url)
    path = uri.path.sub(%r{^/}, '') # Removes the leading /
    quip_thread = quip_client.get_thread(path)

    # The quip api only returns html which has too much extra junk.
    # Convert to md for smaller size
    markdown_quip = ReverseMarkdown.convert quip_thread['html']

    document.document = markdown_quip
    document.synced_at = DateTime.current
    document.external_id = document.source_url
    # TODO: catch sync errors
    document.save

    # add error handling
  end
end
