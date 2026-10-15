# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Question, type: :model do
  let(:user) { create(:user) }

  it 'is valid with valid attributes' do
    question = Question.new(question: 'What is Ruby?', prompt: 'Programming Language', user:)
    expect(question).to be_valid
  end

  it 'is not valid without a question' do
    question = Question.new(question: nil, prompt: 'Programming Language', user:)
    expect(question).not_to be_valid
  end

  it 'is valid without a prompt' do
    question = Question.new(question: 'What is Ruby?', prompt: nil, user:)
    expect(question).to be_valid
  end

  it 'sets able_to_answer to false if answer includes "I am unable"' do
    question = Question.create(question: 'What is Ruby?', prompt: 'Programming Language',
                               answer: 'I am unable to answer the question', user:)
    expect(question.able_to_answer).to eq(false)
  end

  it 'keeps able_to_answer as true if answer does not include "I am unable"' do
    question = Question.create(question: 'What is Ruby?', prompt: 'Programming Language',
                               answer: 'Ruby is a dynamic, open source programming language.', user:)
    expect(question.able_to_answer).to eq(true)
  end

  describe '#slack_markdown_answer' do
    def slack(answer)
      Question.new(question: 'q', answer:).slack_markdown_answer
    end

    it 'returns nil without an answer' do
      expect(slack(nil)).to be_nil
    end

    it 'converts headings, bold, bullets, and links to Slack mrkdwn' do
      answer = "# ANSWER\nThe **cause** is here.\n\n- Step one\n  * Sub step\n\n# DOCUMENTS\n1. [Doc 1](http://host/doc/1)"
      expect(slack(answer)).to eq("*ANSWER*\nThe *cause* is here.\n\n• Step one\n  • Sub step\n\n*DOCUMENTS*\n1. <http://host/doc/1|Doc 1>")
    end

    it 'converts the (text)[url] links used by older answers' do
      expect(slack('1. (Doc 1)[http://host/doc/1]')).to eq('1. <http://host/doc/1|Doc 1>')
    end

    it 'leaves code blocks unchanged and drops the fence language' do
      answer = "```text\n# not a heading **x**\n```"
      expect(slack(answer)).to eq("```\n# not a heading **x**\n```")
    end

    it 'truncates on a line boundary within the Slack limit' do
      answer = Array.new(100) { |i| "Line #{i} #{'x' * 40}" }.join("\n")
      result = slack(answer)
      expect(result.length).to be <= Question::SLACK_MAX_LENGTH
      expect(result).to end_with("#{'x' * 40}...")
    end

    it 'closes a code block cut off by truncation' do
      answer = "```\n#{Array.new(100) { 'x' * 40 }.join("\n")}"
      result = slack(answer)
      expect(result.length).to be <= Question::SLACK_MAX_LENGTH
      expect(result).to end_with("\n```")
    end
  end
end
