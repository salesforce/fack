class WebhooksController < BaseWebhooksController
  before_action :set_webhook, only: %i[show edit update destroy]

  def show
  end

  def new
    @webhook = Webhook.new
  end
end
