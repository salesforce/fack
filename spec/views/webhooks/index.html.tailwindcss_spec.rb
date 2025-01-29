require 'rails_helper'

RSpec.describe "webhooks/index", type: :view do
  before(:each) do
    assign(:webhooks, [
      Webhook.create!(
        secret_key: "Secret Key",
        assistant: nil,
        type: 2
      ),
      Webhook.create!(
        secret_key: "Secret Key",
        assistant: nil,
        type: 2
      )
    ])
  end

  it "renders a list of webhooks" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("Secret Key".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
  end
end
