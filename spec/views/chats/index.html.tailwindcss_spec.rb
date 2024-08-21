require 'rails_helper'

RSpec.describe "chats/index", type: :view do
  before(:each) do
    assign(:chats, [
      Chat.create!(
        assistant: nil
      ),
      Chat.create!(
        assistant: nil
      )
    ])
  end

  it "renders a list of chats" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
