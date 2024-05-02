# frozen_string_literal: true

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

  validates :length, presence: true

  validates :document, presence: true,
                       uniqueness: { scope: :check_hash, message: 'Document with same content already exists.' }

  before_validation :calculate_length, :calculate_tokens, :calculate_hash

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

    errors.add(:token_count, "is #{token_count} and must be less than 8,000")
  end
end
