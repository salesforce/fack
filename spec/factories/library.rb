# frozen_string_literal: true

FactoryBot.define do
  factory :library do
    # Define attributes for Library model
    # For example:
    name { 'Main Library' }
    association :user
  end
end
