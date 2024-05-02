# frozen_string_literal: true

FactoryBot.define do
  factory :api_token do
    association :user
    name { 'My Api Token' }
    active { true }
  end
end
