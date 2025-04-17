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
  let(:encoded_client_id) { 'encoded_client_id' }
  let(:encoded_client_secret) { 'encoded_client_secret' }
  let(:encoded_username) { 'encoded_username' }
  let(:encoded_password) { 'encoded_password' }
  let(:org_url) { 'https://salesforce_org' }
  let(:success_response) { { 'access_token' => 'test_token', 'instance_url' => 'https://salesforce_org' } }

  before do
    allow(ENV).to receive(:[]).with('EGPT_GEN_MODEL').and_return('')
    allow(ENV).to receive(:[]).with('SALESFORCE_CONNECT_CLIENT_ID').and_return(encoded_client_id)
    allow(ENV).to receive(:[]).with('SALESFORCE_CONNECT_CLIENT_SECRET').and_return(encoded_client_secret)
    allow(ENV).to receive(:fetch).with('EMBEDDING_MODEL', 'llmgateway__AzureOpenAITextEmbeddingAda_002').and_return('')
    allow(ENV).to receive(:fetch).with('SALESFORCE_CONNECT_USERNAME', nil).and_return(encoded_username)
    allow(ENV).to receive(:fetch).with('SALESFORCE_CONNECT_PASSWORD', nil).and_return(encoded_password)
    allow(ENV).to receive(:fetch).with('SALESFORCE_CONNECT_ORG_URL', nil).and_return(org_url)
  end

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

  describe '#get_salesforce_connect_oauth_token' do
    context 'when using credential flow' do
      before do
        allow(ENV).to receive(:fetch).with('USE_CREDENTIAL_FLOW_AUTHENTICATION', '').and_return('true')
      end

      it 'sends the request with client credentials' do
        mock_http = instance_double(Net::HTTP)
        mock_response = instance_double(Net::HTTPSuccess)

        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:request).and_return(mock_response)
        allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(mock_response).to receive(:body).and_return(success_response.to_json)

        result = instance.send(:get_salesforce_connect_oauth_token)
        expect(result).to eq(success_response)
        expect(mock_http).to have_received(:request) do |request|
          expect(request).to be_a(Net::HTTP::Post)
          expect(request.path).to eq('/services/oauth2/token')
          body = URI.decode_www_form(request.body).to_h
          expect(body['grant_type']).to eq('client_credentials')
          expect(body['client_id']).to eq(encoded_client_id)
          expect(body['client_secret']).to eq(encoded_client_secret)
          expect(body).not_to have_key('username')
          expect(body).not_to have_key('password')
        end
      end
    end

    context 'when not using credential flow' do
      before do
        allow(ENV).to receive(:fetch).with('USE_CREDENTIAL_FLOW_AUTHENTICATION', '').and_return('false')
      end

      it 'sends the request with password grant' do
        mock_http = instance_double(Net::HTTP)
        mock_response = instance_double(Net::HTTPSuccess)

        allow(Net::HTTP).to receive(:new).and_return(mock_http)
        allow(mock_http).to receive(:use_ssl=)
        allow(mock_http).to receive(:request).and_return(mock_response)
        allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(mock_response).to receive(:body).and_return(success_response.to_json)

        result = instance.send(:get_salesforce_connect_oauth_token)
        expect(result).to eq(success_response)
        expect(mock_http).to have_received(:request) do |request|
          expect(request).to be_a(Net::HTTP::Post)
          expect(request.path).to eq('/services/oauth2/token')
          body = URI.decode_www_form(request.body).to_h
          expect(body['grant_type']).to eq('password')
          expect(body['client_id']).to eq(encoded_client_id)
          expect(body['client_secret']).to eq(encoded_client_secret)
          expect(body['username']).to eq(encoded_username)
          expect(body['password']).to eq(encoded_password)
        end
      end
    end
  end
end
