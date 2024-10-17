class Assistant < ApplicationRecord
  has_many :chats, dependent: :destroy
  belongs_to :user

  enum status: { development: 0, ready: 1 }

  # Add this line to make the libraries field required
  validates :libraries, presence: true

  validates :input, presence: true

  validate :libraries_must_be_csv_with_numbers

  # Override as_json to exclude specific fields
  def as_json(options = {})
    super(options.merge({ except: %i[created_at updated_at id user_prompt llm_prompt] }))
  end

  private

  def libraries_must_be_csv_with_numbers
    return if libraries.blank?

    # Split the string by commas and check if each element is a valid number
    csv_parts = libraries.split(',')
    return unless csv_parts.any? { |part| part.blank? || !(part =~ /\A\d+(\.\d+)?\z/) }

    errors.add(:libraries, 'must be a valid CSV format with only numbers')
  end
end
