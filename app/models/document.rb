class Document < ApplicationRecord
  include PgSearch::Model

  has_many :documents_questions
  has_many :questions, through: :documents_questions

  pg_search_scope :search_by_title_and_document,
                  against: %i[title document],
                  using: {
                    tsearch: { prefix: true } # This option allows partial matches
                  }

  has_neighbors :embedding
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
                       uniqueness: { scope: :check_hash, message: 'Document with same content already exists.' },
                       unless: -> { source_url.present? }

  before_validation :calculate_length, :calculate_tokens, :calculate_hash

  after_save :sync_quip_doc_if_needed
  after_commit :schedule_embed_document_job, if: -> { previous_changes.include?('check_hash') }

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

    return unless synced_at.nil? # only schedule if it is for the initial sync

    return if last_sync_result == 'SCHEDULED' # Prevent duplicate

    self.last_sync_result = 'SCHEDULED'

    SyncQuipDocJob.set(wait: 5.seconds).perform_later(id) # Add delay to prevent race condition with schedule jobs
  end

  # Schedule the EmbedDocumentJob with a delay based on the number of jobs in the queue
  def schedule_embed_document_job
    total_jobs = Delayed::Job.count
    delay_seconds = total_jobs * 3 # 3-second delay per job in the queue

    # Set the priority and delay, and queue the job if the check_hash has changed
    EmbedDocumentJob.set(priority: 5, wait: delay_seconds.seconds).perform_later(id)
  end
end
