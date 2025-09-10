# frozen_string_literal: true

# spec/factories/documents.rb

FactoryBot.define do
  factory :document do
    title { 'Sample Document' }
    document { 'This is a sample document for testing.' }
    association :library
    association :user
  end
end
