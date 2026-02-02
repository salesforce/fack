# MCP Quick Reference

One-page reference for Fack MCP integration.

## Installation

```bash
cd mcp-server && ./install.sh
```

## Configuration

Add to Cursor/Claude Desktop config:

```json
{
  "mcpServers": {
    "fack": {
      "command": "node",
      "args": ["/absolute/path/to/fack/mcp-server/index.js"]
    }
  }
}
```

## Available Tools

| Tool | Purpose | Required Args | Optional Args |
|------|---------|---------------|---------------|
| `ask_question` | AI Q&A from docs | `question` | `library_ids[]` |
| `list_libraries` | List all libraries | - | `page` |
| `search_documents` | Search docs | `query` | `library_id`, `page` |
| `get_document` | Get doc content | `document_id` | - |
| `create_document` | Create new doc | `title`, `document`, `library_id` | `external_id` |
| `list_assistants` | List AI assistants | - | `page` |
| `create_chat` | Start chat | `assistant_id` | - |
| `send_message` | Chat message | `chat_id`, `content` | - |
| `get_chat_messages` | Chat history | `chat_id` | - |

## Authentication

**First time:** Browser opens → Login → Authorize → Done  
**After:** Token stored in `~/.fack-mcp/token.json`

## Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `FACK_URL` | Remote Fack instance | Auto-detected localhost |
| `FACK_TOKEN` | Pre-configured token | Generated via browser auth |

## Endpoints (Rails)

| Path | Method | Purpose |
|------|--------|---------|
| `/mcp/authorize` | GET | Show auth page |
| `/mcp/callback` | POST | Create token |
| `/mcp/token_info` | GET | Validate token |
| `/mcp/revoke` | DELETE | Revoke token |

## Files

```
mcp-server/
├── index.js                     # Main MCP server
├── package.json                 # Dependencies
├── install.sh                   # Installation script
├── test-connection.js           # Connection test
├── README.md                    # Full docs
├── QUICK_START.md              # Quick start
└── *-config-example.json       # Config templates

app/
├── controllers/
│   └── mcp_controller.rb       # Auth endpoints
└── views/mcp/
    ├── authorize.html.erb      # Auth UI
    └── show_token.html.erb     # Fallback token display

~/.fack-mcp/
└── token.json                   # Stored token (600 perms)
```

## Common Commands

```bash
# Install
cd mcp-server && ./install.sh

# Test connection
npm test

# Run manually (for debugging)
node index.js

# Delete token (re-auth)
rm ~/.fack-mcp/token.json
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Can't find Fack" | Ensure running on localhost:3000 or set FACK_URL |
| "Auth required" | Delete ~/.fack-mcp/token.json and restart |
| "Token invalid" | Revoke in Fack UI, delete token file, re-auth |
| "Browser won't open" | Copy URL from console and open manually |

## Security Notes

- Tokens stored in home directory only
- File permissions: 600 (owner read/write only)
- Tokens can be revoked in Fack UI at `/api_tokens`
- Browser auth prevents accidental token exposure
- Never committed to git (in .gitignore)

## Example Usage

**In Cursor:**
```
"What libraries are available in Fack?"
"Ask Fack: How do I configure SSL?"
"Search my engineering docs for kubernetes"
"Create a document about API versioning in library 3"
```

**In Claude Desktop:**
```
"Check my Fack documentation for deployment steps"
"List all assistants in Fack"
"Start a chat with assistant 5 about code review practices"
```

## Architecture

```
Client (Cursor/Claude)
    ↓ MCP Protocol
MCP Server (Node.js)
    ↓ REST API (Bearer Token)
Fack Rails App
    ↓ PostgreSQL + OpenAI/Salesforce
AI-Generated Answers
```

## More Info

- [Full MCP Integration Guide](mcp-integration.md)
- [Main README](../README.md)
- [Fack REST API Docs](../README.md#rest-api)
