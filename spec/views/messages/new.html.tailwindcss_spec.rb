require 'rails_helper'

RSpec.describe "messages/new", type: :view do
  before(:each) do
    assign(:message, Message.new(
      chat: nil,
      content: "MyText",
      from: 1
    ))
  end

  it "renders new message form" do
    render

    assert_select "form[action=?][method=?]", messages_path, "post" do

      assert_select "input[name=?]", "message[chat_id]"

      assert_select "textarea[name=?]", "message[content]"

      assert_select "input[name=?]", "message[from]"
    end
  end
end
