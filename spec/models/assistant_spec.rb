require 'rails_helper'

RSpec.describe Assistant, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it { should validate_presence_of(:libraries) }
    it { should validate_presence_of(:input) }
    it { should validate_presence_of(:instructions) }
    it { should validate_presence_of(:output) }

    context 'libraries CSV validation' do
      it 'is valid with a valid CSV string of numbers' do
        assistant = Assistant.new(libraries: '1,2,3.5,4', input: 'input', user:, instructions: 'instructions', output: 'output')
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
  end
end
