require 'rails_helper'

RSpec.describe GptConcern do
  let(:test_class) { Class.new { include GptConcern } }
  let(:instance) { test_class.new }

  describe '#replace_tag_with_random' do
    it 'replaces a tag with a random string' do
      input = 'Hello {{tag}} world'
      result = instance.replace_tag_with_random(input, '{{tag}}')

      expect(result).to match(/^Hello [a-f0-9]{20} world$/)
      expect(result).not_to include('{{tag}}')
    end
  end

  describe '#get_embedding' do
    context 'when OPENAI_API_KEY is present' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test_key')
        allow(instance).to receive(:call_openai_embedding).and_return([0.1, 0.2, 0.3])
      end

      it 'calls OpenAI embedding API' do
        expect(instance).to receive(:call_openai_embedding).with('test input')
        instance.get_embedding('test input')
      end
    end

    context 'when OPENAI_API_KEY is not present' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
        allow(instance).to receive(:call_salesforce_connect_gpt_embedding).and_return([0.1, 0.2, 0.3])
      end

      it 'calls Salesforce Connect GPT embedding API' do
        expect(instance).to receive(:call_salesforce_connect_gpt_embedding).with('test input')
        instance.get_embedding('test input')
      end
    end
  end

  describe '#get_generation' do
    context 'when OPENAI_API_KEY is present' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return('test_key')
        allow(instance).to receive(:call_openai_generation).and_return('generated text')
      end

      it 'calls OpenAI generation API' do
        expect(instance).to receive(:call_openai_generation).with('test prompt')
        instance.get_generation('test prompt')
      end
    end

    context 'when OPENAI_API_KEY is not present' do
      before do
        allow(ENV).to receive(:[]).with('OPENAI_API_KEY').and_return(nil)
        allow(instance).to receive(:call_salesforce_connect_gpt_generation).and_return('generated text')
      end

      it 'calls Salesforce Connect GPT generation API' do
        expect(instance).to receive(:call_salesforce_connect_gpt_generation).with('test prompt')
        instance.get_generation('test prompt')
      end
    end
  end

  describe '#call_openai_embedding' do
    let(:success_response) do
      double('response',
             code: 200,
             body: '{"data": [{"embedding": [0.1, 0.2, 0.3]}]}')
    end

    let(:error_response) do
      double('response',
             code: 401,
             message: 'Unauthorized')
    end

    before do
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test_key')
    end

    it 'returns embedding when API call is successful' do
      allow(HTTParty).to receive(:post).and_return(success_response)
      result = instance.call_openai_embedding('test input')
      expect(result).to eq([0.1, 0.2, 0.3])
    end

    it 'returns nil when API call fails' do
      allow(HTTParty).to receive(:post).and_return(error_response)
      result = instance.call_openai_embedding('test input')
      expect(result).to be_nil
    end
  end

  describe '#call_openai_generation' do
    let(:success_response) do
      double('response',
             code: 200,
             body: '{"choices": [{"message": {"content": "generated text"}}]}')
    end

    let(:error_response) do
      double('response',
             code: 401,
             message: 'Unauthorized')
    end

    before do
      allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test_key')
      allow(ENV).to receive(:[]).with('EGPT_GEN_MODEL').and_return('gpt-3.5-turbo')
    end

    it 'returns generated text when API call is successful' do
      allow(HTTParty).to receive(:post).and_return(success_response)
      result = instance.call_openai_generation('test prompt')
      expect(result).to eq('generated text')
    end

    it 'returns empty string when API call fails' do
      allow(HTTParty).to receive(:post).and_return(error_response)
      result = instance.call_openai_generation('test prompt')
      expect(result).to eq('')
    end
  end

  describe '#call_salesforce_connect_gpt_embedding' do
    let(:oauth_token) do
      {
        'access_token' => 'test_token',
        'instance_url' => 'https://test.salesforce.com'
      }
    end

    let(:success_response) do
      double('response',
             is_a?: true,
             body: '{"embeddings": [{"embedding": [0.1, 0.2, 0.3]}]}')
    end

    let(:error_response) do
      double('response',
             is_a?: false,
             body: '{"message": "Error"}')
    end

    let(:http) { double('http') }
    let(:request) { double('request') }

    before do
      allow(instance).to receive(:get_salesforce_connect_oauth_token).and_return(oauth_token)
      allow(ENV).to receive(:fetch).with('EMBEDDING_MODEL', 'llmgateway__AzureOpenAITextEmbeddingAda_002')
                                   .and_return('test_model')
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(success_response)
      allow(Net::HTTP::Post).to receive(:new).and_return(request)
      allow(request).to receive(:body=)
      allow(request).to receive(:[]=)
    end

    it 'returns embedding when API call is successful' do
      result = instance.call_salesforce_connect_gpt_embedding('test input')
      expect(result).to eq([0.1, 0.2, 0.3])
    end

    it 'returns nil when API call fails' do
      allow(http).to receive(:request).and_return(error_response)
      result = instance.call_salesforce_connect_gpt_embedding('test input')
      expect(result).to be_nil
    end
  end

  describe '#call_salesforce_connect_gpt_generation' do
    let(:oauth_token) do
      {
        'access_token' => 'test_token',
        'instance_url' => 'https://test.salesforce.com'
      }
    end

    let(:success_response) do
      double('response',
             body: '{"generations": [{"text": "&lt;generated&gt; text"}]}')
    end

    before do
      allow(instance).to receive(:get_salesforce_connect_oauth_token).and_return(oauth_token)
      allow(ENV).to receive(:[]).with('EGPT_MAX_TOKENS').and_return('3000')
      allow(ENV).to receive(:[]).with('EGPT_GEN_MODEL').and_return('gpt-4')
      allow(HTTParty).to receive(:post).and_return(success_response)
    end

    it 'returns decoded generated text when API call is successful' do
      result = instance.call_salesforce_connect_gpt_generation('test prompt')
      expect(result).to eq('<generated> text')
    end

    it 'returns empty string when an error occurs' do
      allow(HTTParty).to receive(:post).and_raise(StandardError.new('API Error'))
      result = instance.call_salesforce_connect_gpt_generation('test prompt')
      expect(result).to eq('')
    end
  end

  describe '#get_salesforce_connect_oauth_token' do
    let(:success_response) do
      double('response',
             is_a?: true,
             body: '{"access_token": "test_token", "instance_url": "https://test.salesforce.com"}')
    end

    let(:error_response) do
      double('response',
             is_a?: false,
             body: '{"error": "invalid_grant"}',
             code: 401)
    end

    let(:http) { double('http') }
    let(:request) { double('request') }

    before do
      allow(ENV).to receive(:fetch).with('SALESFORCE_CONNECT_CLIENT_ID', '').and_return('client_id')
      allow(ENV).to receive(:fetch).with('SALESFORCE_CONNECT_CLIENT_SECRET', '').and_return('client_secret')
      allow(ENV).to receive(:fetch).with('SALESFORCE_CONNECT_USERNAME', nil).and_return('username')
      allow(ENV).to receive(:fetch).with('SALESFORCE_CONNECT_PASSWORD', nil).and_return('password')
      allow(ENV).to receive(:fetch).with('USE_CREDENTIAL_FLOW_AUTHENTICATION', '').and_return('false')
      allow(ENV).to receive(:fetch).with('SALESFORCE_CONNECT_ORG_URL', nil).and_return('https://test.salesforce.com')
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:request).and_return(success_response)
      allow(Net::HTTP::Post).to receive(:new).and_return(request)
      allow(request).to receive(:set_form_data)
      allow(request).to receive(:[]=)
    end

    it 'returns token when authentication is successful' do
      result = instance.send(:get_salesforce_connect_oauth_token)
      expect(result).to eq({ 'access_token' => 'test_token', 'instance_url' => 'https://test.salesforce.com' })
    end

    it 'returns nil when authentication fails' do
      allow(http).to receive(:request).and_return(error_response)
      result = instance.send(:get_salesforce_connect_oauth_token)
      expect(result).to be_nil
    end

    context 'with credential flow authentication' do
      before do
        allow(ENV).to receive(:fetch).with('USE_CREDENTIAL_FLOW_AUTHENTICATION', '').and_return('true')
      end

      it 'uses client credentials flow' do
        instance.send(:get_salesforce_connect_oauth_token)
        expect(Net::HTTP).to have_received(:new)
      end
    end
  end
end
