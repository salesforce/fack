require 'rails_helper'

RSpec.describe Question, type: :model do
  let(:user) { create(:user) }

  it 'is valid with valid attributes' do
    question = Question.new(question: 'What is Ruby?', prompt: 'Programming Language', user: user)
    expect(question).to be_valid
  end

  it 'is not valid without a question' do
    question = Question.new(question: nil, prompt: 'Programming Language', user: user)
    expect(question).not_to be_valid
  end

  it 'is valid without a prompt' do
    question = Question.new(question: 'What is Ruby?', prompt: nil, user: user)
    expect(question).to be_valid
  end

  it 'sets able_to_answer to false if answer includes "I am unable"' do
    question = Question.create(question: 'What is Ruby?', prompt: 'Programming Language',
                               answer: 'I am unable to answer the question', user: user)
    expect(question.able_to_answer).to eq(false)
  end

  it 'keeps able_to_answer as true if answer does not include "I am unable"' do
    question = Question.create(question: 'What is Ruby?', prompt: 'Programming Language',
                               answer: 'Ruby is a dynamic, open source programming language.', user: user)
    expect(question.able_to_answer).to eq(true)
  end
end
