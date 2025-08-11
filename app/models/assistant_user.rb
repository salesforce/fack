class AssistantUser < ApplicationRecord
  belongs_to :user
  belongs_to :assistant

  enum role: { admin: 0, editor: 1 }
end
