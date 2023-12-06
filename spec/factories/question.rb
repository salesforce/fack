FactoryBot.define do
  factory :question do
    association :library
    question { 'What time is it?' }
    prompt { 'Use the documents to answer the question.  <CONTEXT>Doc 1 Doc 2 Doc 3</CONTEXT> What time is it?' }
    answer { '1pm Pacific' }
  end
end
