class Chat < ApplicationRecord
  belongs_to :assistant
  belongs_to :user
  has_many :messages, dependent: :destroy
end
