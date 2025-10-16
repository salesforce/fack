# Chrome Extension Authentication - Quick Testing Guide

## Quick Start

### 1. Reload the Extension
```bash
# Go to chrome://extensions/
# Find your extension
# Click the reload icon (🔄)
```

### 2. Test Authentication

1. **Open Side Panel**: Click extension icon
2. **Click "Authenticate with SSO"**
3. **Watch for**:
   - A new Chrome auth window opens (separate from tabs)
   - You see your SSO login page
   - After login, window closes automatically
   - Side panel shows you're authenticated

### 3. Check Console Logs

**Background Service Worker Console** (chrome://extensions/ → Service Worker)
```
Chrome Identity Redirect URL: https://<ext-id>.chromiumapp.org/oauth
Starting authentication flow: http://localhost:3000/auth/get_token?redirect_uri=...
Authentication completed, response URL: https://<ext-id>.chromiumapp.org/oauth?token=user@example.com
Token extracted successfully
Token stored in chrome.storage
```

**Rails Server Console**
```
=== AUTH GET_TOKEN CALLED ===
Current user: user@example.com
Redirect URI param: https://<ext-id>.chromiumapp.org/oauth
✅ User authenticated successfully: user@example.com
Redirecting to Chrome extension: https://<ext-id>.chromiumapp.org/oauth?token=user@example.com
```

## Expected Behavior

### ✅ Success Flow
1. Auth window opens in separate window (not a tab)
2. User logs in via SSO
3. Window shows "Redirecting..." message briefly
4. Window closes automatically
5. Side panel updates to show authenticated state

### ❌ Common Issues

#### Auth window doesn't open
- Check manifest.json has `"identity"` permission
- Reload extension
- Check background console for errors

#### Window doesn't close automatically
- Check if redirect happened (Rails logs)
- Verify redirect URL includes token parameter
- Check background console for URL parsing errors

#### "No token received" error
- Check Rails redirect URL in logs
- Verify `allow_other_host: true` in controller
- Ensure `params[:redirect_uri]` is not empty

## Verify Everything Works

### 1. Check Token Storage
```javascript
// In background service worker console
chrome.storage.local.get(['apiToken'], (result) => {
  console.log('Token:', result.apiToken);
});
```

### 2. Test API Call
1. Type a question in side panel
2. Click "Ask Question"
3. Should get response without authentication errors

### 3. Test Logout
1. Click "Logout" button
2. Token should be cleared
3. Should show authentication button again

## Differences from Old Flow

| Old (Tab-Based) | New (chrome.identity) |
|-----------------|----------------------|
| Opens new tab | Opens auth window |
| Tab stays open | Window auto-closes |
| Uses content script | No content script needed |
| Manual window close | Automatic closure |
| Less secure | More secure |

## Debug Commands

### View all storage
```javascript
chrome.storage.local.get(null, (items) => {
  console.log('Storage:', items);
});
```

### Clear storage
```javascript
chrome.storage.local.clear(() => {
  console.log('Storage cleared');
});
```

### Test redirect URL generation
```javascript
console.log(chrome.identity.getRedirectURL('oauth'));
// Should output: https://<extension-id>.chromiumapp.org/oauth
```

## Testing Checklist

- [ ] Extension loads without errors
- [ ] Click authenticate opens auth window (not tab)
- [ ] Auth window shows Rails login page
- [ ] After SSO login, see "Redirecting..." message
- [ ] Auth window closes automatically
- [ ] Side panel shows authenticated state
- [ ] Token appears in chrome.storage
- [ ] API calls work with token
- [ ] Logout clears token
- [ ] Re-authentication works

## Next Steps

Once basic flow works:
1. Test with different users
2. Test error scenarios (cancel auth, network issues)
3. Test token validation endpoint
4. Test with production environment
5. Remove legacy auth-content.js if not needed

