# MCP OAuth Setup (Remote + Browser Auth)

The **best of both worlds**: Remote setup (no local code) + OAuth (no manual token).

## How It Works

Instead of manually creating an API token, you:
1. Visit a URL in your browser
2. Click "Authorize"
3. Get a ready-to-paste config
4. Paste into Cursor/Claude
5. Done!

This combines the simplicity of remote setup with the convenience of OAuth.

## Setup Steps

### 1. Visit the OAuth Page

Go to: **http://localhost:3000/mcp/connect**

(Or for remote: `https://your-fack-instance.com/mcp/connect`)

### 2. Authorize

- If not logged in, you'll be prompted to login
- Click "Authorize & Get Config"
- You'll see a complete config ready to copy

### 3. Copy & Paste

The page shows you exactly what to paste:

```json
{
  "mcpServers": {
    "fack": {
      "url": "http://localhost:3000/mcp",
      "headers": {
        "Authorization": "Bearer abc123..."
      }
    }
  }
}
```

Just copy the entire block!

### 4. Configure Cursor/Claude

**For Cursor:**
1. Open Settings (⌘+,)
2. Search for "MCP"
3. Paste the config

**For Claude Desktop:**
1. Open `~/Library/Application Support/Claude/claude_desktop_config.json`
2. Paste the config

### 5. Restart & Use

Restart Cursor/Claude Desktop and try:
- "What libraries are in Fack?"
- "Ask Fack: How do I deploy?"

## Comparison of All Three Approaches

| Method | Setup Time | Local Code | Auth Type | Best For |
|--------|-----------|------------|-----------|----------|
| **Remote + OAuth** (This) | 1 min | ❌ None | ✅ Browser | **Most users** |
| Remote + Manual Token | 1 min | ❌ None | Manual | Power users |
| Local Node.js | 3 min | ✅ Node.js | ✅ Browser | Offline work |

## Why This is Best

✅ **No local code** - Just your Rails server  
✅ **No manual token creation** - OAuth handles it  
✅ **One-click authorization** - Simple browser flow  
✅ **Works from anywhere** - Just need the URL  
✅ **Secure** - Token created via authenticated session  

## Advanced: Share the Link

You can share the authorization link with team members:

**Your team members:**
1. Visit: `https://fack.yourcompany.com/mcp/connect`
2. Login with their account
3. Click authorize
4. Get their own personalized config
5. Paste into their Cursor/Claude

Each person gets their own API token tied to their account!

## Token Management

Tokens created this way appear in your API Tokens page as:
```
MCP Client - Cursor/Claude - 2024-02-02 14:30
```

You can:
- View all MCP tokens
- Revoke individual tokens
- See when each was last used

Go to: http://localhost:3000/api_tokens

## Security Notes

The token is displayed on screen after authorization. This is secure because:
- User must be authenticated to authorize
- Token is tied to their account
- Token can be revoked anytime
- No token is stored in Fack (only in user's config)

## Automating for Teams

For enterprise deployments, you could:

1. **Share the link** in onboarding docs:
   ```
   Get MCP access: https://fack.company.com/mcp/connect
   ```

2. **Add to dashboard** - Put a "Connect MCP" button on your Fack homepage

3. **Auto-provision** - Create tokens automatically on first login

## Troubleshooting

**"Not logged in" error**
→ Login first at your Fack instance

**"Token not working"**
→ Make sure you copied the entire config block

**Need a new token?**
→ Visit `/mcp/connect` again to generate a new one

## Compare to Other Methods

### Remote + Manual Token
```bash
# Manual: Go to /api_tokens, create token, copy, paste
```

### Remote + OAuth (This)
```bash
# Easier: Go to /mcp/connect, click button, copy, paste
```

### Local Node.js
```bash
# Most complex: Install Node.js, run install.sh, configure path, first use opens browser
```

## Example Flow

```
User: "I want to use Fack with Cursor"
You: "Visit http://localhost:3000/mcp/connect"

[User clicks link]
[Sees nice UI explaining MCP]
[Clicks "Authorize & Get Config"]
[Gets ready-to-paste config with token]
[Copies config]
[Pastes into Cursor settings]
[Restarts Cursor]

User: "What's in my Fack libraries?"
Cursor: [Shows libraries from Fack]

Done in 60 seconds! 🎉
```

## Conclusion

This is the **recommended setup** for 99% of users:
- ✅ Simplest (no local code)
- ✅ Fastest (1 minute)
- ✅ Most secure (OAuth via authenticated session)
- ✅ Best UX (beautiful UI, clear instructions)
- ✅ Team-friendly (share the link)

The only reason to use Local Node.js setup is if you need offline support.

---

**Next Steps:**
1. Try it now: http://localhost:3000/mcp/connect
2. Full remote docs: [mcp-remote-setup.md](mcp-remote-setup.md)
3. Quick start: [mcp-remote-quickstart.md](mcp-remote-quickstart.md)
