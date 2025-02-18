FactoryBot.define do
  factory :assistant do
    user_prompt { 'MyText' }
    llm_prompt { 'MyText' }
    libraries { '1' }
    input { 'some input' }
    name { 'Test Assistant' }
    association :user
  end
end
