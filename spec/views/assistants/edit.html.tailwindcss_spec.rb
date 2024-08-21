require 'rails_helper'

RSpec.describe "assistants/edit", type: :view do
  let(:assistant) {
    Assistant.create!(
      user_prompt: "MyText",
      llm_prompt: "MyText",
      libraries: "MyText"
    )
  }

  before(:each) do
    assign(:assistant, assistant)
  end

  it "renders the edit assistant form" do
    render

    assert_select "form[action=?][method=?]", assistant_path(assistant), "post" do

      assert_select "textarea[name=?]", "assistant[user_prompt]"

      assert_select "textarea[name=?]", "assistant[llm_prompt]"

      assert_select "textarea[name=?]", "assistant[libraries]"
    end
  end
end
