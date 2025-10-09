FactoryBot.define do
  factory :assistant do
    user_prompt { 'MyText' }
    llm_prompt { 'MyText' }
    libraries { '1' }
    input { 'some input' }
    name { 'Test Assistant' }
    instructions { 'Sample instructions' }
    output { 'Sample output' }
    slack_reply_only { false }
    association :user
  end
end
