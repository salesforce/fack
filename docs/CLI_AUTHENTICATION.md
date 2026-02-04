# CLI Authentication

This guide explains how to authenticate with the FACK CLI using the OAuth-style flow.

## Overview

The CLI authentication system allows users to securely obtain API tokens for command-line tools without manually copying tokens from the web interface. It uses a localhost redirect flow similar to Heroku CLI and GitHub CLI.

## How It Works

1. **CLI starts local server** - A temporary HTTP server starts on `localhost:9090`
2. **Browser opens** - Your default browser opens to the authorization page
3. **User authorizes** - You review and approve the CLI access request
4. **Token created** - A new API token is created with source="cli"
5. **Redirect to localhost** - The token is sent back to your local CLI via redirect
6. **Token saved** - The CLI saves the token to `~/.fack/credentials`

```
┌─────────┐         ┌──────────┐         ┌──────────┐
│   CLI   │────────▶│ Browser  │────────▶│  Server  │
│         │  Opens  │          │  Login  │          │
└─────────┘         └──────────┘         └──────────┘
     ▲                                          │
     │                                          │
     │         Token via redirect               │
     └──────────────────────────────────────────┘
            http://127.0.0.1:9090/callback
```

## Usage

### Option 1: Using the Ruby Script

```bash
# Default (uses localhost:3000 or $FACK_HOST)
ruby scripts/cli_login.rb

# Specify production host
ruby scripts/cli_login.rb --host https://your-fack-instance.com

# Specify custom port
ruby scripts/cli_login.rb --port 8080

# Both
ruby scripts/cli_login.rb --host https://your-fack-instance.com --port 8080
```

### Option 2: Manual Flow

If you want to implement your own CLI tool:

```ruby
require 'webrick'
require 'securerandom'

state = SecureRandom.hex(32)
port = 9090

# Start server
server = WEBrick::HTTPServer.new(Port: port)
server.mount_proc('/callback') do |req, res|
  if req.query['state'] == state
    token = req.query['token']
    # Save token
    File.write('~/.fack/credentials', token)
    res.body = "Success! You can close this window."
    server.shutdown
  end
end

# Open browser
url = "https://your-fack-instance.com/cli/authorize?state=#{state}&port=#{port}"
system("open '#{url}'")

# Wait for callback
server.start
```

## Security Features

### State Parameter
- Random 32-byte hex string
- Prevents CSRF attacks
- Must match between request and callback

### Localhost Only
- Redirect URI restricted to `127.0.0.1` or `localhost`
- Port must be between 1024-65535 (non-privileged)
- Prevents token interception

### Token Management
- Tokens marked with `source: 'cli'` for tracking
- Can be revoked individually from web interface
- Same permissions as web-created tokens

### File Permissions
- Credentials file saved with mode `0600` (user-only)
- Stored at `~/.fack/credentials` by default

## Token Storage Format

The CLI script saves tokens in JSON format:

```json
{
  "token": "abc123...",
  "host": "https://your-fack-instance.com",
  "created_at": "2026-02-04T07:15:00Z"
}
```

## Using the Token

Once authenticated, you can use the token in your CLI tools:

```ruby
# Read token
credentials = JSON.parse(File.read(File.expand_path('~/.fack/credentials')))
token = credentials['token']

# Make authenticated request
require 'net/http'
require 'uri'

uri = URI('https://your-fack-instance.com/api/v1/documents')
request = Net::HTTP::Get.new(uri)
request['Authorization'] = "Bearer #{token}"

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end
```

Or use curl:

```bash
TOKEN=$(jq -r .token ~/.fack/credentials)
curl -H "Authorization: Bearer $TOKEN" https://your-fack-instance.com/api/v1/documents
```

## Managing CLI Tokens

### View All Tokens
Visit `/api_tokens` in your web browser to see all your tokens, including CLI tokens which are marked with a blue "CLI" badge.

### Revoke a Token
1. Go to `/api_tokens`
2. Click on the CLI token you want to revoke
3. Click "Delete"

### Distinguish Token Types
- **CLI tokens**: Blue badge, named "CLI Token - [date]"
- **Web tokens**: Gray badge, custom names
- **Mobile tokens**: Green badge (future use)

## Troubleshooting

### Port Already in Use
```bash
# Use a different port
ruby scripts/cli_login.rb --port 9091
```

### Browser Doesn't Open
The URL will be printed to console. Copy and paste it into your browser manually.

### Authentication Times Out
The flow has a 2-minute timeout. If you don't complete authorization in time, run the script again.

### Token Not Saved
Check that `~/.fack` directory is writable:
```bash
mkdir -p ~/.fack
chmod 700 ~/.fack
```

## Implementation Details

### Backend Routes

```ruby
# config/routes.rb
get  'cli/authorize', to: 'cli_auth#new'
post 'cli/authorize', to: 'cli_auth#create'
```

### Controller Actions

- `GET /cli/authorize` - Shows authorization page (requires login)
- `POST /cli/authorize` - Creates token and redirects to localhost

### Database Schema

The `api_tokens` table includes:
- `source` (string): 'web', 'cli', or 'mobile'
- Index on `source` for filtering

### Model Scopes

```ruby
# Get only CLI tokens
ApiToken.cli_tokens

# Get only web tokens
ApiToken.web_tokens

# Check token source
token.source_cli?  # => true/false
```

## Future Enhancements

Possible improvements:
- Token expiration dates
- Scope-based permissions (read-only tokens)
- Device fingerprinting
- Token refresh mechanism
- Integration with password managers
