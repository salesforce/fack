require 'rails_helper'

RSpec.describe "messages/edit", type: :view do
  let(:message) {
    Message.create!(
      chat: nil,
      content: "MyText",
      from: 1
    )
  }

  before(:each) do
    assign(:message, message)
  end

  it "renders the edit message form" do
    render

    assert_select "form[action=?][method=?]", message_path(message), "post" do

      assert_select "input[name=?]", "message[chat_id]"

      assert_select "textarea[name=?]", "message[content]"

      assert_select "input[name=?]", "message[from]"
    end
  end
end
