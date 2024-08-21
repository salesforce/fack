require 'rails_helper'

RSpec.describe "messages/show", type: :view do
  before(:each) do
    assign(:message, Message.create!(
      chat: nil,
      content: "MyText",
      from: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/2/)
  end
end
