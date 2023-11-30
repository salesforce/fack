FactoryBot.define do
  factory :question do
    association :library
    question { "What time is it?" }
  end
end
