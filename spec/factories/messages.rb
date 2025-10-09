FactoryBot.define do
  factory :message do
    association :chat
    association :user
    content { "MyText" }
    from { :user }
    status { :ready }
  end
end
