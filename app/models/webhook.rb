class Webhook < ApplicationRecord
  belongs_to :assistant

  enum type: { pagerduty: 0 }

  before_create :generate_secret_key

  private

  def generate_secret_key
    self.secret_key = SecureRandom.hex(20) # Generates a 40-character key
  end
end
