FactoryBot.define do
    factory :api_token do
      association :user
      name { "My Api Token" }
      # The token is generated automatically by the model callback
    end
  end