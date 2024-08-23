FactoryBot.define do
  factory :message do
    chat { nil }
    content { "MyText" }
    from { 1 }
  end
end
