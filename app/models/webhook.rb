class Webhook < ApplicationRecord
  belongs_to :assistant
  belongs_to :library
  has_many :chats

  enum hook_type: { pagerduty: 0 }
  validates :hook_type, presence: true

  before_create :generate_secret_key

  private

  def generate_secret_key
    self.secret_key = SecureRandom.hex(20) # Generates a 40-character key
  end
end
