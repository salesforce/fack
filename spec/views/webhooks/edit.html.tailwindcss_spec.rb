require 'rails_helper'

RSpec.describe "webhooks/edit", type: :view do
  let(:webhook) {
    Webhook.create!(
      secret_key: "MyString",
      assistant: nil,
      type: 1
    )
  }

  before(:each) do
    assign(:webhook, webhook)
  end

  it "renders the edit webhook form" do
    render

    assert_select "form[action=?][method=?]", webhook_path(webhook), "post" do

      assert_select "input[name=?]", "webhook[secret_key]"

      assert_select "input[name=?]", "webhook[assistant_id]"

      assert_select "input[name=?]", "webhook[type]"
    end
  end
end
