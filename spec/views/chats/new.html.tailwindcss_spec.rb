require 'rails_helper'

RSpec.describe "chats/new", type: :view do
  before(:each) do
    assign(:chat, Chat.new(
      assistant: nil
    ))
  end

  it "renders new chat form" do
    render

    assert_select "form[action=?][method=?]", chats_path, "post" do

      assert_select "input[name=?]", "chat[assistant_id]"
    end
  end
end
