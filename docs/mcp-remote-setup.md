# MCP Remote Setup (No Local Code!)

This is the **truly minimal configuration** approach - your Rails server IS the MCP server. No local Node.js process needed!

## How It Works

```
Cursor/Claude Desktop
    ↓ HTTP/SSE
Your Fack Rails Server (Remote or Localhost)
    ↓ Direct API calls
PostgreSQL + OpenAI/Salesforce
```

The client connects directly to your Rails server via HTTP. No local code, no installation, just a URL!

## Configuration

### For Cursor

Add to your Cursor settings:

```json
{
  "mcpServers": {
    "fack": {
      "url": "http://localhost:3000/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_TOKEN_HERE"
      }
    }
  }
}
```

### For Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "fack": {
      "url": "http://localhost:3000/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_TOKEN_HERE"
      }
    }
  }
}
```

### For Remote Instances

Just change the URL:

```json
{
  "mcpServers": {
    "fack": {
      "url": "https://fack.yourcompany.com/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_TOKEN_HERE"
      }
    }
  }
}
```

## Getting Your API Token

1. Start your Fack server: `rails s`
2. Go to http://localhost:3000/api_tokens
3. Create a new token
4. Copy it and paste into your config

That's it!

## Available Endpoints

### Simple HTTP API (Easiest)

These are simple REST endpoints that don't require full MCP protocol:

#### List Tools
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/mcp/tools
```

#### Call a Tool
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool": "list_libraries", "arguments": {}}' \
  http://localhost:3000/mcp/call
```

#### Ask a Question
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tool": "ask_question", "arguments": {"question": "How do I deploy?"}}' \
  http://localhost:3000/mcp/call
```

### Full MCP Protocol (Advanced)

For clients that implement the full MCP protocol:

#### SSE Stream
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/mcp/sse
```

#### JSON-RPC Messages
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list",
    "params": {}
  }' \
  http://localhost:3000/mcp/message
```

## Available Tools

Same tools as the local MCP server:

- **ask_question** - AI Q&A from your docs
- **list_libraries** - Show document libraries
- **search_documents** - Search for documents
- **get_document** - Get document content
- (More coming soon!)

## Comparison: Local vs Remote

### Local MCP Server (Node.js)

**Pros:**
- No server configuration needed
- Auto-detects localhost
- Browser-based auth (no manual token)
- Works offline (if Fack is local)

**Cons:**
- Requires Node.js installation
- Extra process running locally
- More files to maintain

**Config:**
```json
{
  "fack": {
    "command": "node",
    "args": ["/path/to/mcp-server/index.js"]
  }
}
```

### Remote MCP Server (This Approach)

**Pros:**
- **No local code whatsoever**
- **Just a URL + token**
- Works from anywhere
- Simpler architecture
- No installation needed

**Cons:**
- Need to get API token manually
- Must be online

**Config:**
```json
{
  "fack": {
    "url": "http://localhost:3000/mcp",
    "headers": {
      "Authorization": "Bearer YOUR_TOKEN"
    }
  }
}
```

## Which Should You Use?

### Use Remote (This) If:
- ✅ You want the absolute simplest setup
- ✅ You don't mind getting an API token manually
- ✅ Your Fack instance is always online
- ✅ You want to connect from multiple machines

### Use Local (Node.js) If:
- ✅ You want browser-based auth (no manual token)
- ✅ You need offline support
- ✅ You prefer auto-configuration

## Security Notes

### Token in Config File

Your API token will be in plain text in your config file. This is standard for MCP servers, but keep in mind:

- Config file is in your home directory
- Don't commit it to git
- You can revoke the token anytime in Fack UI
- Use HTTPS in production

### Alternative: Environment Variable

Some MCP clients support environment variables:

```json
{
  "fack": {
    "url": "http://localhost:3000/mcp",
    "headers": {
      "Authorization": "Bearer ${FACK_TOKEN}"
    }
  }
}
```

Then set `export FACK_TOKEN=your_token_here` in your shell.

## Troubleshooting

### "Connection refused"
Make sure Fack is running:
```bash
curl http://localhost:3000/api/v1/libraries
```

### "Unauthorized"
Check your token:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/mcp/tools
```

### "Tools not showing up"
Check CORS settings and logs in `log/development.log`

## Example Usage

Once configured, use it in Cursor/Claude:

```
"What libraries are in Fack?"
→ Calls list_libraries

"Ask Fack: How do I configure SSL?"
→ Calls ask_question

"Search Fack for kubernetes docs"
→ Calls search_documents
```

## Conclusion

This is the **absolute minimum configuration** possible:
1. Get an API token from Fack
2. Add URL + token to client config
3. Done!

No installation, no local processes, no complex setup. Just a URL and a token.
