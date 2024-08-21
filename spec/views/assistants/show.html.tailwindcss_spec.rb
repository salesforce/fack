require 'rails_helper'

RSpec.describe "assistants/show", type: :view do
  before(:each) do
    assign(:assistant, Assistant.create!(
      user_prompt: "MyText",
      llm_prompt: "MyText",
      libraries: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyText/)
  end
end
