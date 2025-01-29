require 'rails_helper'

RSpec.describe "webhooks/show", type: :view do
  before(:each) do
    assign(:webhook, Webhook.create!(
      secret_key: "Secret Key",
      assistant: nil,
      type: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Secret Key/)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
  end
end
