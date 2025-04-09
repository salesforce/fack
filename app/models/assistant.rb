class Assistant < ApplicationRecord
  include PgSearch::Model

  has_many :chats, dependent: :destroy
  belongs_to :user
  belongs_to :library, optional: true
  enum status: { development: 0, ready: 1 }
  validates :name, presence: true
  validates :slack_channel_name, uniqueness: true, allow_blank: true
  validate :slack_channel_name_starts_with_unique

  validate :libraries_must_be_csv_with_numbers

  pg_search_scope :search_by_text,
                  against: %i[name description instructions],
                  using: {
                    tsearch: { prefix: true, dictionary: 'english',
                               tsvector_column: 'search_vector' } # This option allows partial matches
                  }

  # Override as_json to exclude specific fields
  def as_json(options = {})
    super(options.merge({ except: %i[created_at updated_at id user_prompt llm_prompt] }))
  end

  private

  def slack_channel_name_starts_with_unique
    return if slack_channel_name_starts_with.blank?

    conflict_exists = Assistant
                      .where.not(id:) # Exclude self if updating
                      .where(
                        "slack_channel_name_starts_with LIKE ? OR ? LIKE slack_channel_name_starts_with || '%'",
                        "#{slack_channel_name_starts_with}%",
                        slack_channel_name_starts_with
                      )
                      .exists?

    return unless conflict_exists

    errors.add(:slack_channel_name_starts_with, 'conflicts with existing entries')
  end

  def libraries_must_be_csv_with_numbers
    return true if libraries.blank?

    # Split the string by commas and check if each element is a valid number
    csv_parts = libraries.split(',')
    return unless csv_parts.any? { |part| part.blank? || !(part =~ /\A\d+(\.\d+)?\z/) }

    errors.add(:libraries, 'must be a valid CSV format with only numbers')
  end
end
