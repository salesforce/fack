# frozen_string_literal: true

class ApiToken < ApplicationRecord
  validates :token, presence: true, uniqueness: true
  validates :name, presence: true

  before_validation :generate_token, on: :create

  belongs_to :user
  # encrypts :token, deterministic: true

  # Source tracking: where was this token created?
  enum :source, { web: 'web', cli: 'cli', mobile: 'mobile' }, prefix: true

  # Scopes for filtering
  scope :cli_tokens, -> { where(source: 'cli') }
  scope :web_tokens, -> { where(source: 'web') }

  private

  def generate_token
    self.token = Digest::MD5.hexdigest(SecureRandom.hex)
    self.active = true
  end
end
