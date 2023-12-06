require 'rails_helper'

RSpec.describe Question, type: :model do
  it 'is valid with valid attributes' do
    question = Question.new(question: 'What is Ruby?', prompt: 'Programming Language')
    expect(question).to be_valid
  end

  it 'is not valid without a question' do
    question = Question.new(question: nil, prompt: 'Programming Language')
    expect(question).not_to be_valid
  end

  it 'is not valid without a prompt' do
    question = Question.new(question: 'What is Ruby?', prompt: nil)
    expect(question).not_to be_valid
  end
end
