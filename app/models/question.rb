class Question < ApplicationRecord
  has_neighbors :embedding

  # Tracking helpful answers
  acts_as_votable

  enum status: { pending: 0, generating: 1, generated: 2, failed: 3 }

  validates :question, presence: true
  belongs_to :user, optional: true

  before_save :check_unable_to_answer

  def slack_markdown_answer
    return if self.answer.nil?
    # Regular expression to match Markdown links
    # \[([^]]+)\] - Matches the link text inside square brackets
    # \(http[^)]+\) - Matches the URL inside parentheses
    markdown_regex = /\[([^\]]+)\]\((http[^)]+)\)/
    
    # Replace each Markdown link with Slack's format
    self.answer.gsub(markdown_regex) do |_match|
      link_text = ::Regexp.last_match(1)
      url = ::Regexp.last_match(2)
      "<#{url}|#{link_text}>"
    end
  end

  private

  def check_unable_to_answer
    return unless answer&.include?('I am unable to answer the question')

    self.able_to_answer = false
  end


end
