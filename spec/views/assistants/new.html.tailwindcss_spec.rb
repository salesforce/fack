require 'rails_helper'

RSpec.describe "assistants/new", type: :view do
  before(:each) do
    assign(:assistant, Assistant.new(
      user_prompt: "MyText",
      llm_prompt: "MyText",
      libraries: "MyText"
    ))
  end

  it "renders new assistant form" do
    render

    assert_select "form[action=?][method=?]", assistants_path, "post" do

      assert_select "textarea[name=?]", "assistant[user_prompt]"

      assert_select "textarea[name=?]", "assistant[llm_prompt]"

      assert_select "textarea[name=?]", "assistant[libraries]"
    end
  end
end
