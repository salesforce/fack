class Chat < ApplicationRecord
  belongs_to :assistant
  belongs_to :user
  belongs_to :webhook
  has_many :messages, dependent: :destroy
  validates :first_message, presence: true
  validates :assistant_id, presence: true
end
