# Chrome Extension Authentication

This document describes how the Chrome extension authenticates with the Rails API.

## Overview

The extension uses a **tab-based authentication flow** with SSO (SAML). This approach:
- ✅ Works in all environments (development, staging, production)
- ✅ Simple and reliable
- ✅ Uses standard Rails SSO authentication
- ✅ No complex OAuth configuration needed

## Authentication Flow

```
1. User clicks "Authenticate with SSO" in extension
   ↓
2. Extension opens /auth/get_token in new tab (background.js)
   ↓
3. If not authenticated → Rails redirects to SSO login
   ↓
4. User completes SSO authentication
   ↓
5. Rails renders auth page with token in DOM (#token-display element)
   ↓
6. Extension's content script (auth-content.js) reads token from page
   ↓
7. Content script sends token to background via chrome.runtime.sendMessage()
   ↓
8. Background script stores token and closes auth tab
   ↓
9. Extension uses token for all API calls
```

## Implementation

### 1. Manifest (manifest.json)

```json
{
  "permissions": [
    "storage",      // Store API token
    "tabs",         // Create/close auth tabs
    "scripting"     // Inject content script
  ],
  "host_permissions": [
    "http://localhost:3000/*"
  ],
  "optional_host_permissions": [
    "http://*/*",   // User can grant access to any HTTP domain
    "https://*/*"   // User can grant access to any HTTPS domain
  ]
}
```

**Note:** Optional permissions are requested dynamically when user configures their server URL.

### 2. Background Script (background.js)

Opens auth tab and listens for token:

```javascript
async authenticateWithTab() {
  return new Promise((resolve) => {
    const authUrl = `${this.baseUrl}/auth/get_token`;
    
    chrome.tabs.create({ url: authUrl, active: true }, (tab) => {
      const authTabId = tab.id;
      
      // Inject content script when page loads
      chrome.tabs.onUpdated.addListener(function listener(tabId, info) {
        if (tabId === authTabId && info.status === 'complete') {
          chrome.scripting.executeScript({
            target: { tabId: authTabId },
            files: ['auth-content.js']
          });
        }
      });
      
      // Listen for token message from content script
      chrome.runtime.onMessage.addListener((message, sender) => {
        if (sender.tab?.id === authTabId && 
            message.type === 'FACK_AUTH_TOKEN') {
          
          // Store token
          this.token = message.token;
          chrome.storage.local.set({ apiToken: this.token });
          
          // Close auth tab
          chrome.tabs.remove(authTabId);
          resolve({ success: true, token: this.token });
        }
      });
    });
  });
}
```

### 3. Content Script (auth-content.js)

Extracts token from page and sends to background:

```javascript
// Find token in DOM
const tokenDisplay = document.getElementById('token-display');
const token = tokenDisplay.getAttribute('data-token');

// Send to background script
chrome.runtime.sendMessage({
  type: 'FACK_AUTH_TOKEN',
  success: true,
  token: token
});
```

### 4. Rails Controller (auth_controller.rb)

```ruby
class AuthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:get_token]
  skip_before_action :require_login, only: [:get_token]

  def get_token
    if current_user
      # Render page with token (extension reads it from DOM)
    else
      # Redirect to SSO login
      redirect_to new_session_path(redirect_to: request.fullpath)
    end
  end
end
```

### 5. Auth View (get_token.html.erb)

```erb
<div id="token-display" data-token="<%= current_user&.email %>">
  <%= current_user&.email %>
</div>

<script>
  // Broadcast token via custom event for content script
  window.dispatchEvent(new CustomEvent('fackAuthToken', { 
    detail: { token: '<%= j current_user&.email %>' }
  }));
</script>
```

## Configuration

### User Setup

1. Install extension
2. Open sidepanel → Configuration
3. Enter server URL (e.g., `https://fack.internal.salesforce.com`)
4. Click "Save Settings" → Chrome asks for permission
5. Click "Allow" to grant access to that domain
6. Click "Authenticate with SSO"
7. Complete SSO login
8. Extension captures token automatically

### Dynamic Permissions

The extension requests permissions **dynamically** when users configure their server URL:

```javascript
// When user saves base URL in settings
async updateConfiguration(baseUrl) {
  const urlPattern = `${new URL(baseUrl).origin}/*`;
  
  // Request permission for this URL
  const granted = await chrome.permissions.request({
    origins: [urlPattern]
  });
  
  if (granted) {
    this.baseUrl = baseUrl;
    await chrome.storage.local.set({ baseUrl });
  } else {
    throw new Error('Permission denied');
  }
}
```

This allows the extension to work with **any deployment** without hardcoding domains in the manifest.

## Security Features

1. **SSO Authentication**: Uses existing enterprise SSO
2. **Dynamic Permissions**: Users explicitly grant access to each domain
3. **Token Storage**: Tokens stored in Chrome's encrypted local storage
4. **Isolated Extension**: Each extension instance has isolated storage
5. **Automatic Cleanup**: Auth tabs close automatically after token capture

## Development

### Local Setup

```bash
# Start Rails server
rails server

# Load extension
1. Go to chrome://extensions/
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select chrome-extension folder

# Test authentication
1. Open extension sidepanel
2. Base URL should be http://localhost:3000 (default)
3. Click "Authenticate with SSO"
4. Complete login
5. Token captured automatically
```

### Console Logs

**Background console (chrome://extensions → Service Worker):**
```
🔐 Using tab-based authentication
📑 Auth tab created with ID: 1234567890
📄 Page loaded in auth tab: http://localhost:3000/auth/get_token
✅ Script injected successfully
📨 Background received message: FACK_AUTH_TOKEN from tab: 1234567890
✅ Received auth token from correct tab: admin@fack.com
💾 Token saved to storage, closing auth tab
```

**Auth page console:**
```
🔧 Auth content script loaded for: http://localhost:3000/auth/get_token
✅ This is an auth page, will look for token
🔍 Looking for token in page...
✅ Found valid token: admin@fack.com
🚀 Sending token to service worker: admin@fack.com
```

## Troubleshooting

### Token not captured

**Check:**
1. Is `auth-content.js` injecting? Look for logs in auth page console
2. Does page have `#token-display` element with `data-token` attribute?
3. Is background script receiving the message? Check background console
4. Are tab IDs matching? Compare in logs

### "Permission denied" when saving URL

**User needs to:**
1. Click "Allow" when Chrome shows permission dialog
2. If denied, try saving URL again - dialog will reappear
3. Check chrome://extensions for granted permissions

### Auth window doesn't close

**Possible causes:**
1. Content script not injecting - check manifest has `scripting` permission
2. Message not reaching background - check tab IDs in logs
3. JavaScript error - check auth page console

## Production Deployment

1. Deploy Rails app with SSO configured
2. Users install extension from Chrome Web Store (or load unpacked)
3. Users configure production URL in extension settings
4. Grant permission when prompted
5. Authenticate via SSO

**No code changes needed** - the extension detects the URL and works automatically!

## API Usage

After authentication, all API calls include the token:

```javascript
async makeAPICall(endpoint, options) {
  const response = await fetch(`${this.baseUrl}/api/v1${endpoint}`, {
    headers: {
      'Authorization': `Bearer ${this.token}`,
      'Content-Type': 'application/json'
    },
    ...options
  });
  return response.json();
}
```

## Why This Approach?

We chose tab-based authentication over `chrome.identity.launchWebAuthFlow()` because:

✅ **Simpler**: No OAuth configuration needed  
✅ **Works everywhere**: Localhost, staging, production  
✅ **Easier to debug**: Can inspect auth page like any web page  
✅ **Flexible**: Works with any SSO provider  
✅ **Open-source friendly**: No hardcoded domains in manifest  

For open-source tools, this approach is ideal since users can point it at any server.

