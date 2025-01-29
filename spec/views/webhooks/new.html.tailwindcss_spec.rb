require 'rails_helper'

RSpec.describe "webhooks/new", type: :view do
  before(:each) do
    assign(:webhook, Webhook.new(
      secret_key: "MyString",
      assistant: nil,
      type: 1
    ))
  end

  it "renders new webhook form" do
    render

    assert_select "form[action=?][method=?]", webhooks_path, "post" do

      assert_select "input[name=?]", "webhook[secret_key]"

      assert_select "input[name=?]", "webhook[assistant_id]"

      assert_select "input[name=?]", "webhook[type]"
    end
  end
end
