# Chrome Extension Authentication - Local Development Setup

## Problem

The `chrome.identity.launchWebAuthFlow()` with `chromiumapp.org` redirect URLs doesn't work reliably with **unpacked extensions** during local development. This is because:

1. Unpacked extensions have unstable extension IDs
2. The `chromiumapp.org` domain is intended for published extensions
3. Chrome's identity API behaves differently in development mode

## Solution

For local development (localhost), we use a **localhost callback URL** instead of the Chrome extension redirect URL.

## How It Works

### Development Flow (localhost)

```
Extension detects localhost baseUrl
    ↓
Uses http://localhost:3000/auth/callback as redirect_uri
    ↓
Opens: http://localhost:3000/auth/get_token?redirect_uri=http://localhost:3000/auth/callback
    ↓
User authenticates via SSO
    ↓
Rails redirects to: http://localhost:3000/auth/callback
    ↓
Callback page loads with token in @token variable
    ↓
JavaScript redirects to: http://localhost:3000/auth/callback?token=user@example.com
    ↓
chrome.identity.launchWebAuthFlow intercepts URL with token parameter
    ↓
Extracts token, stores it, closes window
```

### Production Flow (non-localhost)

```
Extension uses chrome.identity.getRedirectURL()
    ↓
Uses https://<ext-id>.chromiumapp.org/oauth as redirect_uri
    ↓
Opens: https://your-app.com/auth/get_token?redirect_uri=https://<ext-id>.chromiumapp.org/oauth
    ↓
User authenticates via SSO
    ↓
Rails redirects to: https://<ext-id>.chromiumapp.org/oauth?token=user@example.com
    ↓
chrome.identity.launchWebAuthFlow intercepts and extracts token
```

## Implementation Details

### 1. Extension (background.js)

```javascript
async authenticateWithSSO() {
  // Detect if using localhost
  const isLocalhost = this.baseUrl.includes('localhost') || 
                      this.baseUrl.includes('127.0.0.1');
  
  let redirectURL;
  if (isLocalhost) {
    // Development: Use localhost callback
    redirectURL = `${this.baseUrl}/auth/callback`;
  } else {
    // Production: Use Chrome extension redirect URL
    redirectURL = chrome.identity.getRedirectURL('oauth');
  }
  
  // Launch auth flow
  chrome.identity.launchWebAuthFlow({
    url: `${this.baseUrl}/auth/get_token?redirect_uri=${encodeURIComponent(redirectURL)}`,
    interactive: true
  }, (responseUrl) => {
    // Extract token from URL and store
  });
}
```

### 2. Rails Controller

```ruby
# app/controllers/auth_controller.rb

def get_token
  if current_user && params[:redirect_uri].present?
    redirect_uri = params[:redirect_uri]
    token = current_user.email
    
    # Redirect to the redirect_uri with token
    separator = redirect_uri.include?('?') ? '&' : '?'
    redirect_url = "#{redirect_uri}#{separator}token=#{CGI.escape(token)}"
    redirect_to redirect_url, allow_other_host: true
  end
end

def callback
  if current_user
    @token = current_user.email
    # Render callback view
  end
end
```

### 3. Callback View

```erb
<!-- app/views/auth/callback.html.erb -->

<script>
  const token = '<%= j @token %>';
  const currentUrl = new URL(window.location.href);
  currentUrl.searchParams.set('token', token);
  
  // Redirect to same URL with token parameter
  // chrome.identity.launchWebAuthFlow will intercept this
  window.location.href = currentUrl.toString();
</script>
```

## Testing Local Development

### 1. Start Rails Server
```bash
cd /Users/vswamidass/dev/fack
rails server
```

### 2. Load Extension
1. Go to `chrome://extensions/`
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select the `chrome-extension` folder

### 3. Test Authentication
1. Click extension icon to open side panel
2. Ensure baseUrl is `http://localhost:3000` (default)
3. Click "🔐 Authenticate with SSO"

### 4. Watch Console Logs

**Background Service Worker:**
```
Using localhost redirect for development: http://localhost:3000/auth/callback
Starting authentication flow: http://localhost:3000/auth/get_token?redirect_uri=...
Authentication completed, response URL: http://localhost:3000/auth/callback?token=admin%40fack.com
Token extracted successfully: admin@fack.com
Token stored in chrome.storage
```

**Rails Server:**
```
=== AUTH GET_TOKEN CALLED ===
Current user: admin@fack.com
Redirect URI param: http://localhost:3000/auth/callback
Redirecting to Chrome extension: http://localhost:3000/auth/callback

=== AUTH CALLBACK CALLED ===
Current user: admin@fack.com
✅ Callback with token: admin@fack.com
```

## Switching Between Development and Production

The extension **automatically detects** whether you're using localhost or a production URL:

### Development (Automatic)
- BaseURL: `http://localhost:3000`
- Redirect: `http://localhost:3000/auth/callback`
- No configuration needed!

### Staging/Production (Automatic)
- BaseURL: `https://your-app.com`
- Redirect: `https://<ext-id>.chromiumapp.org/oauth`
- Works automatically when you change baseUrl in the extension UI

## Troubleshooting

### "No token found in response URL"

**Check Rails logs:**
```ruby
# Should see:
Redirecting to Chrome extension: http://localhost:3000/auth/callback
```

If you don't see the redirect, ensure:
- User is authenticated (check session)
- `redirect_uri` parameter is being passed
- `allow_other_host: true` is set in controller

### Auth window opens but doesn't close

**Check background console:**
```javascript
// Should see:
Authentication completed, response URL: http://localhost:3000/auth/callback?token=...
Token extracted successfully
```

If token extraction fails:
- Check that callback page redirects with `?token=` parameter
- Verify JavaScript in callback view is executing
- Check for JavaScript errors in auth window console

### "Authentication error" in console

**Common causes:**
1. User cancelled the auth window (expected behavior)
2. Rails redirect failed (check Rails logs)
3. Token parameter missing (check callback view)

**Debug steps:**
1. Check Rails server is running
2. Verify you can access http://localhost:3000/auth/callback manually
3. Check for errors in both background console and Rails logs
4. Try authenticating via browser first to ensure SSO works

## Production Deployment

When deploying to production:

1. **No code changes needed** - detection is automatic
2. User configures baseUrl in extension UI to production URL
3. Extension automatically switches to `chromiumapp.org` redirect
4. Rails controller handles both flows identically

## Benefits of This Approach

| Feature | Localhost Callback | chromiumapp.org |
|---------|-------------------|-----------------|
| **Works in dev** | ✅ Always | ❌ Unreliable |
| **Unpacked extensions** | ✅ Perfect | ⚠️ Issues |
| **Debugging** | ✅ Easy (network tab) | ❌ Opaque |
| **Production** | ⚠️ Not needed | ✅ Secure |
| **Automatic switch** | ✅ Yes | ✅ Yes |

## Summary

- **Development**: Uses `localhost/auth/callback` - reliable and debuggable
- **Production**: Uses `chromiumapp.org` - secure and standard
- **Automatic**: Extension detects environment and switches automatically
- **No manual config**: Just set your baseUrl and it works!

🎉 Now you can develop and test the Chrome extension authentication flow locally without any issues!

