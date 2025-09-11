FactoryBot.define do
  factory :comment do
    content { 'This is a helpful comment about the document.' }
    association :document
    association :user
  end
end
