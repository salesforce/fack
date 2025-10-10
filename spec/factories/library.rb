# frozen_string_literal: true

FactoryBot.define do
  factory :library do
    # Define attributes for Library model
    # For example:
    name { 'Main Library' }
    description { 'A comprehensive collection of documents and resources' }
    association :user
  end
end
