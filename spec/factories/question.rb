# frozen_string_literal: true

FactoryBot.define do
  factory :question do
    association :library
    question { 'What time is it?' }
    prompt do
      'Use the documents to answer the question.  <CONTEXT>Doc 1 Doc 2 Doc 3</CONTEXT> What time is it?'
    end
    answer { '1pm Pacific' }
  end
end
