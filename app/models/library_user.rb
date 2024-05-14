class LibraryUser < ApplicationRecord
  belongs_to :user
  belongs_to :library

  enum role: { admin: 0, editor: 1 }
end
