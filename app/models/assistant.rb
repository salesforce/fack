class Assistant < ApplicationRecord
  serialize :libraries, type: Array
  has_many :chats
end
