require 'rails_helper'

RSpec.describe "chats/edit", type: :view do
  let(:chat) {
    Chat.create!(
      assistant: nil
    )
  }

  before(:each) do
    assign(:chat, chat)
  end

  it "renders the edit chat form" do
    render

    assert_select "form[action=?][method=?]", chat_path(chat), "post" do

      assert_select "input[name=?]", "chat[assistant_id]"
    end
  end
end
