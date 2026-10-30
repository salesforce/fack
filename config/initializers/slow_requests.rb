# frozen_string_literal: true

# Logs one line per slow request so they can be found with `heroku logs | grep SLOW_REQUEST`
SLOW_REQUEST_MS = ENV.fetch('SLOW_REQUEST_MS', '2000').to_i

ActiveSupport::Notifications.subscribe('process_action.action_controller') do |event|
  next if event.duration < SLOW_REQUEST_MS

  payload = event.payload
  Rails.logger.warn(
    "SLOW_REQUEST #{payload[:controller]}##{payload[:action]} #{payload[:method]} #{payload[:path]} " \
    "status=#{payload[:status]} total=#{event.duration.round}ms " \
    "db=#{payload[:db_runtime]&.round}ms view=#{payload[:view_runtime]&.round}ms"
  )
end
