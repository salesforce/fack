class Chat < ApplicationRecord
  belongs_to :assistant
  has_many :messages
end
