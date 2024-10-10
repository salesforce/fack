require 'websocket-client-simple'
require 'json'

ws = WebSocket::Client::Simple.connect 'ws://localhost:3000/cable'

# When the connection opens, subscribe to the "MessagesChannel"
ws.on :open do
  puts 'Connected to WebSocket!'

  # Send a subscription request to the "MessagesChannel"
  subscription_message = {
    command: 'subscribe',
    identifier: JSON.generate(channel: 'MessagesChannel')
  }
  ws.send(JSON.generate(subscription_message))
end

ws.on :message do |msg|
  data = JSON.parse(msg.data)
  next if data['type'] == 'ping'

  # Output the message for debugging
  puts "Data #{msg}"

  # Uncomment this if you want to extract specific messages
  puts "Received: #{data['message']['message']}" if data.dig('message', 'message')
end

ws.on :close do |_e|
  puts 'Disconnected!'
end

ws.on :error do |e|
  puts "Error: #{e}"
end

loop do
  # Keep the connection alive
  sleep 1
end
