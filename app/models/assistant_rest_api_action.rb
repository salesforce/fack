class AssistantRestApiAction < ApplicationRecord
  belongs_to :assistant

  validates :endpoint, presence: true
  validates :authorization_header, presence: true

  # Encrypt the authorization header
  encrypts :authorization_header

  # Add a method to safely access the decrypted authorization header
  def decrypted_authorization_header
    authorization_header
  end
end
