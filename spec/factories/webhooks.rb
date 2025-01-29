FactoryBot.define do
  factory :webhook do
    secret_key { "MyString" }
    assistant { nil }
    type { 1 }
  end
end
