require 'rails_helper'

RSpec.describe "assistants/index", type: :view do
  before(:each) do
    assign(:assistants, [
      Assistant.create!(
        user_prompt: "MyText",
        llm_prompt: "MyText",
        libraries: "MyText"
      ),
      Assistant.create!(
        user_prompt: "MyText",
        llm_prompt: "MyText",
        libraries: "MyText"
      )
    ])
  end

  it "renders a list of assistants" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
