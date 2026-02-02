# MCP Setup Comparison - Complete Guide

Three ways to connect Fack to Cursor/Claude Desktop. Choose based on your needs.

## Quick Comparison Table

| Feature | Remote + OAuth ⭐ | Remote + Manual |
|---------|------------------|-----------------|
| **Setup Time** | 1 minute | 1 minute |
| **Steps Required** | 3 steps | 2 steps |
| **Local Code** | ❌ None | ❌ None |
| **Installation** | ❌ None | ❌ None |
| **Auth Type** | ✅ Browser OAuth | Manual token |
| **Token Visibility** | In config | In config |
| **Works Offline** | If Fack local | If Fack local |
| **Team Sharing** | ✅ Share link | Share instructions |
| **Best For** | **99% of users** | Power users |

## Option 1: Remote + OAuth ⭐ RECOMMENDED

### What You Get
- ✅ No local code or installation
- ✅ Browser-based authorization
- ✅ Beautiful UI with clear instructions
- ✅ Ready-to-paste config
- ✅ 60-second setup

### Setup Process
```
1. Visit http://localhost:3000/mcp/connect
2. Click "Authorize & Get Config"
3. Copy the displayed config
4. Paste into Cursor/Claude settings
5. Restart Cursor/Claude
```

### Configuration
```json
{
  "mcpServers": {
    "fack": {
      "url": "http://localhost:3000/mcp",
      "headers": {
        "Authorization": "Bearer auto-generated-token"
      }
    }
  }
}
```

### Pros
- ✅ Simplest overall experience
- ✅ No manual token creation
- ✅ Clear step-by-step UI
- ✅ Works from any machine
- ✅ Easy to share with team
- ✅ No dependencies

### Cons
- ⚠️ Token visible in config file (standard for remote MCP)
- ⚠️ Requires browser for initial setup

### When to Use
- **Default choice for everyone**
- Setting up for the first time
- Want the fastest setup
- Sharing with teammates
- Don't need offline support

### Documentation
- [OAuth Setup Guide](mcp-oauth-setup.md) - Full walkthrough
- [Try it now](http://localhost:3000/mcp/connect) - Live authorization

---

## Option 2: Remote + Manual Token

### What You Get
- ✅ No local code or installation  
- ✅ Maximum control over tokens
- ⚠️ Manual token creation

### Setup Process
```
1. Go to http://localhost:3000/api_tokens
2. Create new API token
3. Copy token
4. Add to config manually
5. Restart Cursor/Claude
```

### Configuration
```json
{
  "mcpServers": {
    "fack": {
      "url": "http://localhost:3000/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_MANUALLY_CREATED_TOKEN"
      }
    }
  }
}
```

### Pros
- ✅ Full control over token name/metadata
- ✅ Can create token via API
- ✅ Good for automation/scripts
- ✅ No browser popup needed

### Cons
- ⚠️ Extra step (create token manually)
- ⚠️ Need to know where to get token
- ⚠️ Less user-friendly than OAuth

### When to Use
- You prefer manual control
- Automating token creation
- Already have API tokens
- Don't want browser-based flow

### Documentation
- [Remote Quick Start](mcp-remote-quickstart.md)
- [Remote Full Guide](mcp-remote-setup.md)

---

## ~~Option 3: Local Node.js Server~~ (Removed)

**This option has been removed in favor of the simpler remote approaches.**

If you need offline support, you can still use the Remote + OAuth or Remote + Manual token methods with a locally-running Fack instance.

---

## Decision Tree

```
Do you want the absolute simplest setup?
├─ YES → Use Remote + OAuth ⭐
└─ NO → Continue

Do you need to automate token creation?
├─ YES → Use Remote + Manual Token
└─ NO → Use Remote + OAuth ⭐
```

## Architecture Comparison

### Remote + OAuth
```
Browser → /mcp/connect → Authorize → Token displayed
Cursor/Claude → HTTP → Rails /mcp/call → Response
```

### Remote + Manual
```
Browser → /api_tokens → Create token → Copy manually
Cursor/Claude → HTTP → Rails /mcp/call → Response
```

## Feature Matrix

| Feature | Remote + OAuth | Remote + Manual |
|---------|----------------|-----------------|
| Zero local code | ✅ | ✅ |
| Browser auth | ✅ | ❌ |
| Token in config | ✅ | ✅ |
| Team friendly | ✅ | ⚠️ |
| Dependencies | None | None |
| Maintenance | None | None |

## Migration Guide

### From Remote Manual to Remote + OAuth
1. Visit http://localhost:3000/mcp/connect
2. Authorize and get new config
3. Replace old token with new token
4. Optional: Revoke old token at /api_tokens

## Recommendations by Use Case

### For Development Teams
**Remote + OAuth** - Easy to share link with team

### For Individual Developers
**Remote + OAuth** - Fastest setup

### For Production/Enterprise
**Remote + Manual** - Automated token provisioning

### For Offline Work
**Remote + OAuth** with local Fack instance - Works when internet down

### For Demos/Onboarding
**Remote + OAuth** - Best UX, beautiful UI

## Common Questions

**Q: Can I use multiple methods?**  
A: Yes! You can have different configs on different machines.

**Q: Which is most secure?**  
A: Both options are secure - tokens can be revoked anytime at /api_tokens.

**Q: Can I switch later?**  
A: Yes, easily! See migration guide above.

**Q: What do you recommend?**  
A: **Remote + OAuth** for 99% of users. Only use Local if you specifically need offline support.

**Q: Can I automate this?**  
A: Yes, use Remote + Manual and create tokens via API.

## Summary

| If you want... | Use this |
|----------------|----------|
| **Simplest setup** | Remote + OAuth ⭐ |
| **Best UX** | Remote + OAuth ⭐ |
| **Team sharing** | Remote + OAuth ⭐ |
| **Automation** | Remote + Manual Token |
| **Max control** | Remote + Manual Token |

**Bottom line: 99% of users should use Remote + OAuth.**

---

## Getting Started

Ready to set up? Visit:
- **[http://localhost:3000/mcp/connect](http://localhost:3000/mcp/connect)** - Remote + OAuth (Recommended)
- [Remote Manual Guide](mcp-remote-quickstart.md) - Manual token

Questions? Check the [OAuth Setup Guide](mcp-oauth-setup.md) or [Remote Setup Guide](mcp-remote-setup.md).
