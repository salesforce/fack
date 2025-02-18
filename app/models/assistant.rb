class Assistant < ApplicationRecord
  has_many :chats, dependent: :destroy
  belongs_to :user
  belongs_to :library, optional: true
  enum status: { development: 0, ready: 1 }
  validates :name, presence: true
  validates :slack_channel_name, uniqueness: true, allow_blank: true

  validate :libraries_must_be_csv_with_numbers

  # Override as_json to exclude specific fields
  def as_json(options = {})
    super(options.merge({ except: %i[created_at updated_at id user_prompt llm_prompt] }))
  end

  private

  def libraries_must_be_csv_with_numbers
    return true if libraries.blank?

    # Split the string by commas and check if each element is a valid number
    csv_parts = libraries.split(',')
    return unless csv_parts.any? { |part| part.blank? || !(part =~ /\A\d+(\.\d+)?\z/) }

    errors.add(:libraries, 'must be a valid CSV format with only numbers')
  end
end
