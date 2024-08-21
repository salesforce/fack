FactoryBot.define do
  factory :assistant do
    user_prompt { "MyText" }
    llm_prompt { "MyText" }
    libraries { "MyText" }
  end
end
