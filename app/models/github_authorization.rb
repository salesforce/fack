class GithubAuthorization < ApplicationRecord
  belongs_to :user

  encrypts :token
end
