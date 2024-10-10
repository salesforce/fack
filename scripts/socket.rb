require 'websocket-client-simple'
require 'json'

# Connect to the WebSocket server
ws = WebSocket::Client::Simple.connect 'ws://localhost:3000/cable'

# Your API token for authentication
api_token = ENV.fetch('API_TOKEN', nil)

# When the connection opens, subscribe to the "MessagesChannel"
ws.on :open do
  puts 'Connected to WebSocket!'

  # Send a subscription request to the "MessagesChannel" with the token
  subscription_message = {
    command: 'subscribe',
    identifier: JSON.generate(channel: 'MessagesChannel', token: api_token)
  }
  ws.send(JSON.generate(subscription_message))
end

# Handle incoming messages
ws.on :message do |msg|
  data = JSON.parse(msg.data)
  next if data['type'] == 'ping' # Skip ping messages

  # Output the message for debugging
  puts "Data: #{msg}"

  # Optionally, extract and display specific messages
  puts "Received: #{data['message']['message']}" if data.dig('message', 'message')
end

# Handle WebSocket connection close
ws.on :close do |_e|
  puts 'Disconnected!'
end

# Handle WebSocket errors
ws.on :error do |e|
  puts "Error: #{e}"
end

# Keep the connection alive
loop do
  sleep 1
end
