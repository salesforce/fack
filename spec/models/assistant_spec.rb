require 'rails_helper'

RSpec.describe Assistant, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    context 'libraries CSV validation' do
      it 'is valid with a valid CSV string of numbers' do
        assistant = Assistant.new(name: 'test', libraries: '1,2,3.5,4', input: 'input', user:, instructions: 'instructions', output: 'output')
        expect(assistant).to be_valid
      end

      it 'is not valid with non-numeric values in libraries' do
        assistant = Assistant.new(libraries: '1,2,three,4', input: 'input', instructions: 'instructions', output: 'output')
        expect(assistant).not_to be_valid
        expect(assistant.errors[:libraries]).to include('must be a valid CSV format with only numbers')
      end

      it 'is not valid with blank values in libraries' do
        assistant = Assistant.new(libraries: '1,,3.5,4', input: 'input', instructions: 'instructions', output: 'output')
        expect(assistant).not_to be_valid
        expect(assistant.errors[:libraries]).to include('must be a valid CSV format with only numbers')
      end
    end

    context 'quip_url validation' do
      it 'is valid with a quip.com URL' do
        assistant = Assistant.new(name: 'test', quip_url: 'https://example.quip.com/document/123', input: 'input', user:, instructions: 'instructions', output: 'output')
        expect(assistant).to be_valid
      end

      it 'is valid with blank quip_url' do
        assistant = Assistant.new(name: 'test', quip_url: '', input: 'input', user:, instructions: 'instructions', output: 'output')
        expect(assistant).to be_valid
      end

      it 'is valid with nil quip_url' do
        assistant = Assistant.new(name: 'test', quip_url: nil, input: 'input', user:, instructions: 'instructions', output: 'output')
        expect(assistant).to be_valid
      end

      it 'is not valid with non-quip URL' do
        assistant = Assistant.new(name: 'test', quip_url: 'https://google.com/document/123', input: 'input', user:, instructions: 'instructions', output: 'output')
        expect(assistant).not_to be_valid
        expect(assistant.errors[:quip_url]).to include('Only quip urls are supported.')
      end

      it 'is not valid with URL that does not contain quip.com' do
        assistant = Assistant.new(name: 'test', quip_url: 'https://example.com/quip/document/123', input: 'input', user:, instructions: 'instructions', output: 'output')
        expect(assistant).not_to be_valid
        expect(assistant.errors[:quip_url]).to include('Only quip urls are supported.')
      end
    end
  end
end
