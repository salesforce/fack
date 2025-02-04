# frozen_string_literal: true

# spec/factories/documents.rb

FactoryBot.define do
  factory :document do
    document { 'This is a sample document for testing.' }
    title { ' The Title ' }
    association :library
  end
end
