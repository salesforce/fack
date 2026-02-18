# frozen_string_literal: true

class ApiToken < ApplicationRecord
  MAX_TOKENS_PER_USER = 2

  validates :token, presence: true, uniqueness: true
  validates :name, presence: true
  validate :user_token_limit, on: :create

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

  def user_token_limit
    return unless user_id.present?
    # Only apply limit to CLI tokens
    return unless source == 'cli'

    active_cli_token_count = user.api_tokens.where(active: true, source: 'cli').count
    if active_cli_token_count >= MAX_TOKENS_PER_USER
      errors.add(:base, "Maximum of #{MAX_TOKENS_PER_USER} active CLI tokens allowed. Please delete an existing CLI token first.")
    end
  end
end
