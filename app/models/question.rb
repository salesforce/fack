# frozen_string_literal: true

class Question < ApplicationRecord
  include PgSearch::Model

  has_neighbors :embedding

  has_many :documents_questions
  has_many :documents, through: :documents_questions

  # Tracking helpful answers
  acts_as_votable

  enum :status, { pending: 0, generating: 1, generated: 2, failed: 3 }

  validates :question, presence: true
  validates :doc_lookback_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  belongs_to :user, optional: true
  validate :library_present, on: :create

  before_save :check_unable_to_answer

  pg_search_scope :search_by_title_and_question,
                  against: %i[title question],
                  using: {
                    tsearch: { prefix: true, dictionary: 'english',
                               tsvector_column: 'search_vector' } # This option allows partial matches
                  }

  # Slack section blocks are limited to 3000 characters
  SLACK_MAX_LENGTH = 3000

  # Converts the markdown answer to Slack mrkdwn, truncated on a line boundary
  def slack_markdown_answer
    return if answer.nil?

    in_code_block = false
    text = answer.lines.map do |line|
      if line.lstrip.start_with?('```')
        in_code_block = !in_code_block
        # Slack shows a fence language (```text) as literal text
        next line.sub(/```\S*/, '```')
      end
      in_code_block ? line : slack_markdown_line(line)
    end.join

    text = text.truncate(SLACK_MAX_LENGTH - 4, separator: "\n")
    text += "\n```" if text.scan('```').length.odd?
    text
  end

  private

  # Questions without a library search every document and time out, so require at least one
  def library_present
    return if library_id.present? || library_ids_included.any?(&:present?)

    errors.add(:base, 'Select at least one library (library_id or library_ids_included) to ask a question.')
  end

  def slack_markdown_line(line)
    line
      .sub(/^[ \t]*\#{1,6}[ \t]+(.+?)[ \t]*$/, '*\1*') # headings
      .sub(/^([ \t]*)[-*+][ \t]+/, '\1• ') # bullets
      .gsub(/\*\*(.+?)\*\*/, '*\1*') # bold
      .gsub(/\[([^\]]+)\]\((http[^)]+)\)/, '<\2|\1>') # [text](url)
      .gsub(/\(([^()]+)\)\[(http[^\]]+)\]/, '<\2|\1>') # (text)[url], used by older answers
  end

  def check_unable_to_answer
    return unless answer&.include?('I am unable to answer the question')

    self.able_to_answer = false
  end
end
