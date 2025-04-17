class Assistant < ApplicationRecord
  include PgSearch::Model

  has_many :chats, dependent: :destroy
  has_many :assistant_rest_api_actions, dependent: :destroy
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

    starts_with = slack_channel_name_starts_with.strip
    return if starts_with.empty?

    conflicting_record = Assistant
                         .where.not(id:)
                         .where.not(slack_channel_name_starts_with: ['', nil])
                         .where(
                           "LOWER(slack_channel_name_starts_with) LIKE LOWER(?) OR LOWER(?) LIKE LOWER(slack_channel_name_starts_with) || '%'",
                           "#{starts_with}%",
                           starts_with
                         )
                         .first # Use .first to get the conflicting record

    return unless conflicting_record

    error_message = 'conflicts with existing entry: '
    error_message += "#{conflicting_record.name} (#{conflicting_record.id}) "

    errors.add(:slack_channel_name_starts_with, error_message)
  end

  def libraries_must_be_csv_with_numbers
    return true if libraries.blank?

    # Split the string by commas and check if each element is a valid number
    csv_parts = libraries.split(',')
    return unless csv_parts.any? { |part| part.blank? || !(part =~ /\A\d+(\.\d+)?\z/) }

    errors.add(:libraries, 'must be a valid CSV format with only numbers')
  end
end
