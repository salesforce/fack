require "net/http"
require "uri"
require "json"

# Configuration
PAGERDUTY_API_URL = "https://events.pagerduty.com/v2/enqueue" # PagerDuty Events API v2
INTEGRATION_KEY = "xx" # Replace with your PagerDuty Integration Key

# Function to post an alert
def post_alert(summary, severity = "info", custom_details = {})
  uri = URI(PAGERDUTY_API_URL)

  headers = {
    "Content-Type" => "application/json",
  }

  # Prepare the payload following PagerDuty’s format
  payload = {
    event_action: "trigger",
    routing_key: INTEGRATION_KEY,
    payload: {
      summary: summary,
      severity: severity,
      source: custom_details[:source] || "server-01", # Default source if not provided
      custom_details: custom_details, # Additional details
    },
  }.to_json

  begin
    response = Net::HTTP.post(uri, payload, headers)

    if response.is_a?(Net::HTTPSuccess)
      puts "Alert posted successfully: #{response.body}"
    else
      puts "Failed to post alert: #{response.code} - #{response.message} - #{response.body}"
    end
  rescue StandardError => e
    puts "Error posting alert: #{e.message}"
  end
end

# Example usage with custom details
custom_details = {
  source: "web-server-02",
  cpu_usage: "97%",
  error_code: "502",
  user: "admin",
  description: "High CPU usage and 502 errors detected",
}

post_alert("Critical: High CPU usage on web-server-02", "critical", custom_details)
