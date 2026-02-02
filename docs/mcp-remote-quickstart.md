# MCP Remote Quick Start (2 Steps!)

The **absolute simplest** way to use Fack with Cursor/Claude Desktop.

## Step 1: Get Your API Token

1. Start Fack: `rails s`
2. Go to http://localhost:3000/api_tokens
3. Click "New API Token"
4. Copy the token

## Step 2: Configure Cursor/Claude

Paste this into your settings:

**For Cursor:**
```json
{
  "mcpServers": {
    "fack": {
      "url": "http://localhost:3000/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_TOKEN_HERE"
      }
    }
  }
}
```

**For Claude Desktop:**
Open `~/Library/Application Support/Claude/claude_desktop_config.json` and add the same.

## That's It!

Restart Cursor/Claude and try:
- "What libraries are in Fack?"
- "Ask Fack: How do I deploy to production?"

## Remote Fack Instance?

Just change the URL:
```json
{
  "url": "https://fack.yourcompany.com/mcp",
  ...
}
```

## Why This is Better

**No local code needed!**
- ❌ No Node.js installation
- ❌ No local server process
- ❌ No install scripts
- ✅ Just a URL and token

Compare to traditional setup:
- Other MCP servers: Install package, run process, configure ports
- Fack Remote: Get token, paste config

## Available Tools

- `ask_question` - AI Q&A from your docs
- `list_libraries` - Show document libraries  
- `search_documents` - Search documents
- `get_document` - Get document by ID

More coming soon!

## Troubleshooting

**"Connection refused"**
→ Make sure Fack is running: `rails s`

**"Unauthorized"**  
→ Check your token at http://localhost:3000/api_tokens

**Test it manually:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/mcp/tools
```

Should return JSON with available tools.

---

**Full documentation:** [mcp-remote-setup.md](mcp-remote-setup.md)
