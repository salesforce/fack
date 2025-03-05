FactoryBot.define do
  factory :google_authorization do
    user { nil }
    access_token { "MyString" }
    refresh_token { "MyString" }
    expires_at { "2025-03-04 13:11:42" }
  end
end
