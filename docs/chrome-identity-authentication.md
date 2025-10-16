# Chrome Extension Authentication with chrome.identity.launchWebAuthFlow()

This document describes the implementation of secure Chrome extension authentication using the `chrome.identity.launchWebAuthFlow()` API.

## Overview

The Chrome extension authentication has been upgraded to use Chrome's official Identity API, which provides a more secure and user-friendly authentication flow compared to tab-based approaches.

## Architecture

### Authentication Flow

```
┌─────────────────┐
│  Chrome         │
│  Extension      │
└────────┬────────┘
         │
         │ 1. Click "Authenticate"
         │
         ▼
┌────────────────────────────────────────┐
│ chrome.identity.getRedirectURL()       │
│ Returns: https://<ext-id>.chromiumapp. │
│          org/oauth                     │
└────────┬───────────────────────────────┘
         │
         │ 2. Launch auth flow
         │
         ▼
┌────────────────────────────────────────┐
│ chrome.identity.launchWebAuthFlow({    │
│   url: "https://app.com/auth/get_token│
│        ?redirect_uri=https://<ext-id>. │
│        chromiumapp.org/oauth",         │
│   interactive: true                    │
│ })                                     │
└────────┬───────────────────────────────┘
         │
         │ 3. Opens secure auth window
         │
         ▼
┌────────────────────────────────────────┐
│ Rails Application                      │
│ /auth/get_token?redirect_uri=...       │
└────────┬───────────────────────────────┘
         │
         │ 4. User authenticates via SSO
         │
         ▼
┌────────────────────────────────────────┐
│ Rails AuthController#get_token         │
│ - Checks if user authenticated         │
│ - Extracts redirect_uri param          │
│ - Redirects to: https://<ext-id>.      │
│   chromiumapp.org/oauth?token=<email>  │
└────────┬───────────────────────────────┘
         │
         │ 5. Redirects with token
         │
         ▼
┌────────────────────────────────────────┐
│ chrome.identity.launchWebAuthFlow()    │
│ - Intercepts redirect                  │
│ - Extracts token from URL              │
│ - Closes auth window                   │
│ - Returns token to extension           │
└────────┬───────────────────────────────┘
         │
         │ 6. Token stored
         │
         ▼
┌────────────────────────────────────────┐
│ chrome.storage.local.set({             │
│   apiToken: token                      │
│ })                                     │
└────────────────────────────────────────┘
```

## Implementation Details

### 1. Chrome Extension Side

#### manifest.json
```json
{
  "permissions": [
    "storage",
    "activeTab",
    "tabs",
    "sidePanel",
    "identity"  // ← New permission added
  ]
}
```

#### background.js
```javascript
async authenticateWithSSO() {
  return new Promise((resolve) => {
    // Get Chrome extension redirect URL
    const redirectURL = chrome.identity.getRedirectURL('oauth');
    // Example: https://<extension-id>.chromiumapp.org/oauth
    
    // Construct auth URL with redirect_uri
    const authUrl = `${this.baseUrl}/auth/get_token?redirect_uri=${encodeURIComponent(redirectURL)}`;
    
    // Launch secure auth flow
    chrome.identity.launchWebAuthFlow(
      {
        url: authUrl,
        interactive: true  // Shows UI for user interaction
      },
      (responseUrl) => {
        // Handle response
        if (chrome.runtime.lastError) {
          resolve({ success: false, error: chrome.runtime.lastError.message });
          return;
        }
        
        // Extract token from URL
        const url = new URL(responseUrl);
        const token = url.searchParams.get('token');
        
        // Store token
        this.token = token;
        chrome.storage.local.set({ apiToken: this.token });
        resolve({ success: true, token: this.token });
      }
    );
  });
}
```

### 2. Rails Application Side

#### app/controllers/auth_controller.rb
```ruby
class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:get_token]
  skip_before_action :require_login, only: [:get_token]

  def get_token
    if current_user
      # Check if redirect_uri is provided (Chrome extension flow)
      if params[:redirect_uri].present?
        redirect_uri = params[:redirect_uri]
        token = current_user.email
        
        # Construct redirect URL with token
        separator = redirect_uri.include?('?') ? '&' : '?'
        redirect_url = "#{redirect_uri}#{separator}token=#{CGI.escape(token)}"
        
        # Redirect back to Chrome extension
        redirect_to redirect_url, allow_other_host: true
      else
        # Legacy flow - render page
        render :get_token
      end
    else
      # Redirect to login
      redirect_to new_session_path(redirect_to: request.fullpath)
    end
  end
end
```

#### app/views/auth/get_token.html.erb
```erb
<% if params[:redirect_uri].present? %>
  <!-- Modern flow: shows "Redirecting..." message -->
  <div class="text-5xl text-blue-500 mb-5 animate-pulse">⟳</div>
  <h1>Redirecting...</h1>
  <p>Authentication successful! Redirecting back to your extension...</p>
<% else %>
  <!-- Legacy flow: shows token for content script capture -->
  <div id="token-display" data-token="<%= current_user&.email %>">
    <%= current_user&.email %>
  </div>
<% end %>
```

## Security Benefits

### Compared to Tab-Based Authentication

| Feature | chrome.identity API | Tab-Based (Old) |
|---------|---------------------|-----------------|
| **Window Type** | Secure auth window | Regular browser tab |
| **Token Capture** | URL redirect (secure) | Content script DOM access |
| **User Experience** | Auto-closes on success | Requires manual close |
| **Content Script** | Not required | Required |
| **Cross-Origin** | Handled by Chrome | Requires CORS/messaging |
| **Security** | Chrome-managed | Extension-managed |
| **Visibility** | Separate auth window | Tab that can be closed |

### Key Security Features

1. **Isolated Authentication Context**: Auth happens in a separate, Chrome-managed window
2. **No DOM Access Required**: Token is passed via URL redirect, not DOM scraping
3. **Automatic Window Closure**: Auth window closes immediately after token capture
4. **Chrome-Managed Flow**: Chrome handles the entire redirect/capture process
5. **Extension ID Validation**: Redirect URL includes extension ID, preventing token theft

## Testing

### 1. Development Environment

```bash
# Start Rails server
rails server

# Load extension in Chrome
# 1. Go to chrome://extensions/
# 2. Enable "Developer mode"
# 3. Click "Load unpacked"
# 4. Select chrome-extension folder
```

### 2. Test Authentication Flow

1. Open Chrome DevTools → Console
2. Click extension icon to open side panel
3. Click "🔐 Authenticate with SSO"
4. Watch console logs:
   ```
   Chrome Identity Redirect URL: https://<ext-id>.chromiumapp.org/oauth
   Starting authentication flow: http://localhost:3000/auth/get_token?redirect_uri=...
   ```
5. Complete SSO login
6. Auth window should close automatically
7. Check console for:
   ```
   Authentication completed, response URL: https://<ext-id>.chromiumapp.org/oauth?token=...
   Token extracted successfully
   Token stored in chrome.storage
   ```

### 3. Verify Token Storage

```javascript
// In Chrome DevTools console (background service worker)
chrome.storage.local.get(['apiToken'], (result) => {
  console.log('Stored token:', result.apiToken);
});
```

### 4. Test API Calls

1. After authentication, type a question in the side panel
2. Click "Ask Question"
3. Verify API calls include the token in Authorization header
4. Check Rails logs for token validation

## Troubleshooting

### "User cancelled the authorization"
- User closed the auth window before completing login
- This is expected behavior - allow user to try again

### "No token found in response URL"
- Check Rails logs - is redirect_uri being handled correctly?
- Verify the redirect URL includes `?token=` or `&token=` parameter
- Check that `allow_other_host: true` is set in Rails redirect

### "Invalid response from server"
- Check if redirect URL is properly formatted
- Verify Chrome extension ID is correct
- Check browser console for URL parsing errors

### Auth window doesn't open
- Check if `identity` permission is in manifest.json
- Verify `chrome.identity.getRedirectURL()` returns a valid URL
- Check for JavaScript errors in background service worker

### Rails doesn't redirect
- Ensure `params[:redirect_uri]` is being passed and recognized
- Check if `allow_other_host: true` is included in redirect
- Verify user is authenticated (check `current_user`)

## Migration from Legacy Flow

The implementation maintains backward compatibility:

1. **With redirect_uri**: Uses new chrome.identity flow
2. **Without redirect_uri**: Falls back to legacy content script flow

To fully migrate:
1. Update all extension installations to use the new flow
2. Monitor usage of legacy flow (check for requests without redirect_uri)
3. Eventually remove auth-content.js and legacy view rendering

## Production Deployment

### 1. Extension Package
- No code changes needed - baseUrl is configurable via UI
- Users can switch between environments

### 2. Rails Configuration
- Ensure HTTPS is enabled
- Update any redirect_uri validation if added
- Test with production SSO provider

### 3. Chrome Web Store
- If publishing to Chrome Web Store, request `identity` permission
- Include explanation of why permission is needed
- Provide screenshots of auth flow

## References

- [Chrome Identity API Documentation](https://developer.chrome.com/docs/extensions/reference/identity/)
- [OAuth2 for Chrome Extensions](https://developer.chrome.com/docs/extensions/mv3/tut_oauth/)
- [launchWebAuthFlow API](https://developer.chrome.com/docs/extensions/reference/identity/#method-launchWebAuthFlow)

## Implementation Checklist

- [x] Add `identity` permission to manifest.json
- [x] Update `authenticateWithSSO()` to use `chrome.identity.launchWebAuthFlow()`
- [x] Modify Rails controller to handle `redirect_uri` parameter
- [x] Update auth view to show redirect message
- [x] Add logging for debugging
- [x] Document the new flow
- [x] Maintain backward compatibility
- [x] Update README with new authentication flow
- [ ] Test with production SSO
- [ ] Monitor and verify successful migrations

