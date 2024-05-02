class ApiToken < ApplicationRecord
  validates :token, presence: true, uniqueness: true
  validates :name, presence: true

  before_validation :generate_token, on: :create

  belongs_to :user
  # encrypts :token, deterministic: true

  private

  def generate_token
    self.token = Digest::MD5.hexdigest(SecureRandom.hex)
    self.active = true
  end
end
