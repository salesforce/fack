# spec/factories/documents.rb

FactoryBot.define do
  factory :document do
    document { "This is a sample document for testing." }
    association :library
  end
end
