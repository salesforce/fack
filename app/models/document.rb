class Document < ApplicationRecord
  include PgSearch::Model

  # Enable flagging functionality
  acts_as_votable

  has_many :documents_questions
  has_many :questions, through: :documents_questions
  has_many :comments, dependent: :destroy
  has_neighbors :embedding

  # Primary search scope using PostgreSQL full-text search
  # Searches across both title and document content with strict word matching
  # - prefix: true allows partial word matching (e.g., "test" matches "testing")
  # - any_word: false requires ALL search terms to be present (AND logic)
  # - Uses precomputed search_vector for performance
  pg_search_scope :search_by_title_and_document,
                  against: %i[title document],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: 'english',
                      tsvector_column: 'search_vector',
                      any_word: true
                    }
                  }

  # Strict search scope with enhanced exact matching
  # Similar to search_by_title_and_document but with stricter ranking:
  # - normalization: 0 disables document length normalization in ranking
  # - This prioritizes exact word matches over document length considerations
  # - Better for finding specific content regardless of document size
  pg_search_scope :strict_search,
                  against: %i[title document],
                  using: {
                    tsearch: {
                      prefix: true,
                      dictionary: 'english',
                      tsvector_column: 'search_vector',
                      any_word: false,
                      normalization: 0 # No normalization - prioritizes exact word matches over document length
                    }
                  }

  # Smart search scope that handles partial word matching like "test12" -> "test"
  # This is chainable and preserves existing filters (library_id, date ranges, etc.)
  scope :smart_search, lambda { |query|
    return all if query.blank?

    strict_results = strict_search(query)
    return strict_results if strict_results.count >= 1

    # Return empty relation if no results found
    none
  }

  # Scope to find related documents by embedding with optional library filtering
  # _limit is the number of documents to return. Returning fewer is better since the most relevant documents are at the top.
  # Because of the ordering, having too many documents may cause the most relevant documents to be lost.
  scope :related_by_embedding, lambda { |embedding, limit = nil|
    limit ||= ENV.fetch('RELATED_DOCUMENTS_LIMIT', 25).to_i
    scope = nearest_neighbors(:embedding, embedding, distance: 'euclidean')
    scope.order(updated_at: :desc).limit(limit)
  }
  belongs_to :library, counter_cache: true
  belongs_to :user

  validates :library, presence: true
  validates :title, presence: true

  # Prevent DDOS and generally excessively large docs
  validates :token_count, presence: true
  validate :token_count_must_be_less_than

  validates :external_id, uniqueness: true, if: -> { external_id.present? }
  validates :source_url, uniqueness: true, if: -> { source_url.present? }

  validates :length, presence: true

  validates :document, presence: true,
                       uniqueness: { scope: :check_hash, message: ->(object, _data) { "Record with same content already exists. '#{object.document[0..9]}...'" } },
                       unless: -> { source_url.present? }

  before_validation :calculate_length, :calculate_tokens, :calculate_hash

  after_save :sync_quip_doc_if_needed
  after_commit :schedule_embed_document_job, if: -> { previous_changes.include?('check_hash') }
  before_save :update_search_vector

  def source_type
    if source_url.include?('quip.com')
      'quip'
    elsif source_url.present?
      'other'
    elsif source_url.blank?
      'none'
    end
  end

  def calculate_length
    # Calculate the length of the 'document' column and store it in the 'length' column
    return unless document

    self.length = document.length
  end

  def calculate_tokens
    self.token_count = (count_tokens(document) if document)
  end

  def calculate_hash
    return unless document

    # get shasum to detect duplicates
    sha = Digest::SHA2.hexdigest(document)
    self.check_hash = sha
  end

  DEFAULT_MODEL = 'gpt-3.5-turbo'
  DEFAULT_EMBED_DELAY = 5 # seconds per job in queue

  def count_tokens(string, model: DEFAULT_MODEL)
    get_tokens(string, model:)
  end

  def get_tokens(string, model: DEFAULT_MODEL)
    encoding = Tiktoken.encoding_for_model(model)
    tokens = encoding.encode(string)
    tokens.length
  end

  # The AI embedding models are currently limited to ~8,000 tokens.
  # https://community.openai.com/t/new-embedding-model-input-size/602476
  def token_count_must_be_less_than
    return unless token_count.present? && token_count >= 8_000

    errors.add(:token_count, "is #{token_count} and must be less than 8,000.  Try shortening the document.")
  end

  # Sync the document with Quip if source_url is present, contains 'quip.com',
  def sync_quip_doc_if_needed
    return unless source_url.present? && source_url.include?('quip.com')
    return unless new_record? || saved_change_to_source_url? # Only schedule if new or source_url changed

    # TODO: improve this dup protection
    self.last_sync_result = 'SCHEDULED'

    SyncQuipDocJob.set(wait: 5.seconds, priority: 10).perform_later(id) # Add delay to prevent race condition with scheduled jobs
  end

  # Schedule the EmbedDocumentJob with a delay based on the number of jobs in the queue
  def schedule_embed_document_job
    return unless document.present?

    doc_priority = 5

    total_jobs = Delayed::Job.where(priority: doc_priority).count
    embed_delay = ENV.fetch('EMBED_DELAY', DEFAULT_EMBED_DELAY).to_i
    delay_seconds = total_jobs * embed_delay # Use configurable delay per job in the queue

    # Set the priority and delay, and queue the job if the check_hash has changed
    EmbedDocumentJob.set(priority: doc_priority, wait: delay_seconds.seconds).perform_later(id)
  end

  def update_search_vector
    # Properly updates the tsvector column using raw SQL
    sanitized_sql = Document.sanitize_sql([
                                            "to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, ''))",
                                            title,
                                            document
                                          ])

    self.search_vector = Document.connection.execute(
      "SELECT #{sanitized_sql} AS tsvector"
    ).first['tsvector']
  end
end
