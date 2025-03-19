# spec/concerns/gpt_concern_spec.rb
require 'rails_helper'

RSpec.describe GptConcern, type: :concern do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new do
      include GptConcern
    end
  end

  let(:instance) { test_class.new }
  let(:sample_input) { 'Test input string' }
  let(:sample_prompt) { 'Test prompt' }

  describe '#replace_tag_with_random' do
    it 'replaces specified tag with a random hex string' do
      input = 'Hello <tag> world'
      result = instance.replace_tag_with_random(input, '<tag>')
      expect(result).to match(/Hello [0-9a-f]{20} world/)
      expect(result).not_to eq(input)
    end
  end

  describe '#get_embedding' do
    context 'when OPENAI_API_KEY is present' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test_key')
      end

      it 'calls OpenAI embedding' do
        expect(instance).to receive(:call_openai_embedding).with(sample_input)
        instance.get_embedding(sample_input)
      end
    end

    context 'when OPENAI_API_KEY is not present' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      end

      it 'calls Salesforce Connect embedding' do
        expect(instance).to receive(:call_salesforce_connect_gpt_embedding).with(sample_input)
        instance.get_embedding(sample_input)
      end
    end
  end

  describe '#get_generation' do
    context 'when OPENAI_API_KEY is present' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test_key')
      end

      it 'calls OpenAI generation' do
        expect(instance).to receive(:call_openai_generation).with(sample_prompt)
        instance.get_generation(sample_prompt)
      end
    end

    context 'when OPENAI_API_KEY is not present' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
      end

      it 'calls Salesforce Connect generation' do
        expect(instance).to receive(:call_salesforce_connect_gpt_generation).with(sample_prompt)
        instance.get_generation(sample_prompt)
      end
    end
  end

  describe '#call_openai_embedding' do
    let(:response_double) { double('Response', code: 200, body: '{"data":[{"embedding":"test_embedding"}]}') }

    before do
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test_key')
      allow(HTTParty).to receive(:post).and_return(response_double)
    end

    it 'returns embedding data on success' do
      expect(instance.call_openai_embedding(sample_input)).to eq('test_embedding')
    end
  end

  describe '#call_openai_generation' do
    let(:response_double) { double('Response', code: 200, body: '{"choices":[{"message":{"content":"test_content"}}]}') }

    before do
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test_key')
      allow(HTTParty).to receive(:post).and_return(response_double)
    end

    it 'returns generated content on success' do
      expect(instance.call_openai_generation(sample_prompt)).to eq('test_content')
    end
  end

  describe '#call_salesforce_connect_gpt_embedding' do
    it 'makes a request to Salesforce endpoint' do
      oauth_token = { 'access_token' => 'test_token', 'instance_url' => 'https://test.salesforce.com' }
      allow(instance).to receive(:get_salesforce_connect_oauth_token).and_return(oauth_token)

      response_double = double('Response', is_a?: true, body: '{"embeddings":[{"embedding":"test_embedding"}]}')
      http_double = double('HTTP', request: response_double)
      allow(http_double).to receive(:use_ssl=).with(true)

      expect(Net::HTTP).to receive(:new).and_return(http_double)
      expect(instance.call_salesforce_connect_gpt_embedding(sample_input)).to eq('test_embedding')
    end
  end
end
