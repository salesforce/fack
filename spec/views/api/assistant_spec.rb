require 'rails_helper'

RSpec.describe 'assistants api', type: :view do
  let(:user) { User.create!(email: 'user@example.com', password: 'Password1!') }

  # Assuming the Assistant model requires these fields
  let(:library) { Library.create!(name: 'Test Library', user:) }
  let(:assistant) { Assistant.create!(name: 'Test Assistant', user:, libraries: '1,2', input: 'Sample input', instructions: 'Sample instructions', output: 'Sample output') }

  before do
    assign(:assistant, assistant)
  end

  context 'when rendering a partial' do
    it 'renders the assistant partial correctly' do
      render partial: 'api/v1/assistants/assistant', locals: { assistant: }

      json = JSON.parse(rendered)

      # Verify the partial's JSON content
      expect(json).to include(
        'id' => assistant.id,
        'created_at' => assistant.created_at.as_json,
        'updated_at' => assistant.updated_at.as_json
      )
    end
  end
end
