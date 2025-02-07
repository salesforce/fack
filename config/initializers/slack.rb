require 'slack-ruby-client'

Slack::Web::Client.configure do |config|
  config.token = ENV.fetch('SLACK_BOT_TOKEN', nil)
end
