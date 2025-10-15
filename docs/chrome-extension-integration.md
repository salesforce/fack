# Chrome Extension Integration Guide

This guide explains how to integrate your Chrome extension with the Rails API authentication system using SSO.

## Overview

The Rails API supports Chrome extension authentication through:
- SSO (SAML) authentication with automatic token generation
- API token-based API access
- CORS-enabled endpoints 
- Secure token transfer mechanism

## Authentication Flow

The Chrome extension authentication uses your existing SSO system:

1. **Extension requests authentication** → Opens `/auth/get_token` in new tab
2. **SSO authentication** → User completes SAML SSO if not already logged in  
3. **Token generation** → Server generates API token for authenticated user
4. **Token display** → User redirected to secure token display page
5. **Token capture** → Extension automatically captures token and closes tab
6. **API access** → Extension uses token for all subsequent API calls

## API Endpoints

### Authentication
- `GET /auth/get_token` - SSO authentication and token generation for extensions
- `GET /auth/token_display` - Secure token display page
- `GET /api/v1/auth/validate` - Validate current token and get user info  
- `POST /api/v1/auth/logout` - Invalidate current token

### Data Access
- `GET /api/v1/chats` - List user's chats
- `POST /api/v1/chats` - Create new chat
- `GET /api/v1/chats/:id/messages` - Get messages for a chat
- `POST /api/v1/chats/:id/messages` - Send message to chat
- ... (other endpoints as needed)

## Chrome Extension Setup

### 1. Manifest (manifest.json)
```json
{
  "manifest_version": 3,
  "name": "Your App Extension",
  "version": "1.0",
  "description": "Chrome extension for your Rails app",
  "permissions": [
    "storage",
    "activeTab"
  ],
  "host_permissions": [
    "http://localhost:3000/*",
    "https://your-production-domain.com/*"
  ],
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"]
    }
  ],
  "action": {
    "default_popup": "popup.html",
    "default_title": "Your App"
  }
}
```

### 2. Background Script (background.js)
```javascript
// API configuration
const API_BASE_URL = 'http://localhost:3000/api/v1'; // Change for production
const AUTH_BASE_URL = 'http://localhost:3000'; // Change for production

class ApiClient {
  constructor() {
    this.token = null;
    this.authWindow = null;
    this.init();
  }

  async init() {
    // Load token from storage
    const result = await chrome.storage.local.get(['apiToken']);
    this.token = result.apiToken;
  }

  async loginWithSSO() {
    return new Promise((resolve) => {
      // Open SSO authentication window
      const authUrl = `${AUTH_BASE_URL}/auth/get_token`;
      
      this.authWindow = window.open(
        authUrl,
        'sso_auth',
        'width=500,height=600,scrollbars=yes,resizable=yes'
      );

      // Listen for token from auth window
      const messageListener = async (event) => {
        // Verify origin for security
        if (event.origin !== AUTH_BASE_URL.replace(/:\d+$/, '').replace(/^https?:\/\//, 'http://').replace('http://', 'http://') && 
            event.origin !== AUTH_BASE_URL.replace('http://', 'https://')) {
          return;
        }

        if (event.data.type === 'FACK_AUTH_TOKEN' && event.data.success) {
          // Store token
          this.token = event.data.token;
          await chrome.storage.local.set({ 
            apiToken: this.token 
          });

          // Notify auth window that token was captured
          if (this.authWindow && !this.authWindow.closed) {
            this.authWindow.postMessage({ type: 'FACK_TOKEN_CAPTURED' }, '*');
          }

          // Clean up
          window.removeEventListener('message', messageListener);
          if (this.authWindow) {
            this.authWindow.close();
            this.authWindow = null;
          }

          // Get user info
          try {
            const userInfo = await this.validateToken();
            resolve({ success: true, user: userInfo.user });
          } catch (error) {
            resolve({ success: true, token: this.token });
          }
        }
      };

      // Add message listener
      window.addEventListener('message', messageListener);

      // Handle window closed manually
      const checkClosed = setInterval(() => {
        if (this.authWindow && this.authWindow.closed) {
          clearInterval(checkClosed);
          window.removeEventListener('message', messageListener);
          this.authWindow = null;
          resolve({ success: false, error: 'Authentication cancelled' });
        }
      }, 1000);

      // Timeout after 5 minutes
      setTimeout(() => {
        clearInterval(checkClosed);
        window.removeEventListener('message', messageListener);
        if (this.authWindow && !this.authWindow.closed) {
          this.authWindow.close();
        }
        this.authWindow = null;
        resolve({ success: false, error: 'Authentication timeout' });
      }, 300000);
    });
  }

  async validateToken() {
    if (!this.token) return { valid: false };

    try {
      const response = await fetch(`${API_BASE_URL}/auth/validate`, {
        headers: {
          'Authorization': `Bearer ${this.token}`,
          'Content-Type': 'application/json'
        }
      });

      const data = await response.json();
      
      if (!data.valid) {
        // Token invalid, clear storage
        await this.logout();
      }
      
      return data;
    } catch (error) {
      return { valid: false, error: error.message };
    }
  }

  async logout() {
    if (this.token) {
      try {
        await fetch(`${API_BASE_URL}/auth/logout`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.token}`,
            'Content-Type': 'application/json'
          }
        });
      } catch (error) {
        console.error('Logout error:', error);
      }
    }

    this.token = null;
    await chrome.storage.local.clear();
  }

  async apiCall(endpoint, options = {}) {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const url = `${API_BASE_URL}${endpoint}`;
    const defaultOptions = {
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    };

    const response = await fetch(url, { ...defaultOptions, ...options });
    
    if (response.status === 401) {
      // Token expired, clear storage
      await this.logout();
      throw new Error('Authentication expired');
    }

    return response.json();
  }

  // Convenience methods for common API calls
  async getChats() {
    return this.apiCall('/chats');
  }

  async createChat(assistantId, message) {
    return this.apiCall('/chats', {
      method: 'POST',
      body: JSON.stringify({
        chat: {
          assistant_id: assistantId,
          first_message: message
        }
      })
    });
  }

  async sendMessage(chatId, content) {
    return this.apiCall(`/chats/${chatId}/messages`, {
      method: 'POST', 
      body: JSON.stringify({
        message: { content }
      })
    });
  }
}

// Global API client instance
const apiClient = new ApiClient();

// Message handling for popup/content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  (async () => {
    try {
      switch (request.action) {
        case 'loginSSO':
          const loginResult = await apiClient.loginWithSSO();
          sendResponse(loginResult);
          break;
          
        case 'logout':
          await apiClient.logout();
          sendResponse({ success: true });
          break;
          
        case 'validateToken':
          const validation = await apiClient.validateToken();
          sendResponse(validation);
          break;
          
        case 'apiCall':
          const result = await apiClient.apiCall(request.endpoint, request.options);
          sendResponse({ success: true, data: result });
          break;
          
        default:
          sendResponse({ success: false, error: 'Unknown action' });
      }
    } catch (error) {
      sendResponse({ success: false, error: error.message });
    }
  })();
  
  return true; // Keep message channel open for async response
});
```

### 3. Popup HTML (popup.html)
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { width: 320px; padding: 20px; }
    button { width: 100%; padding: 12px; background: #007cba; color: white; border: none; cursor: pointer; border-radius: 6px; font-size: 14px; }
    button:hover { background: #005a87; }
    button:disabled { background: #ccc; cursor: not-allowed; }
    .error { color: red; margin-top: 10px; font-size: 13px; }
    .user-info { background: #f8f9fa; padding: 15px; border-radius: 6px; border: 1px solid #dee2e6; }
    .status { text-align: center; padding: 10px; font-size: 13px; color: #666; }
    .title { font-size: 18px; font-weight: bold; margin-bottom: 15px; text-align: center; }
    .login-section { text-align: center; }
    .sso-info { background: #e7f3ff; padding: 10px; border-radius: 4px; font-size: 12px; color: #0066cc; margin-bottom: 15px; }
  </style>
</head>
<body>
  <div class="title">Your App Extension</div>

  <div id="loginForm">
    <div class="sso-info">
      🔐 This extension uses your company SSO for secure authentication
    </div>
    
    <div class="login-section">
      <button id="ssoLoginBtn">Login with SSO</button>
      <div class="status" id="loginStatus"></div>
      <div id="loginError" class="error"></div>
    </div>
  </div>

  <div id="userInfo" style="display: none;">
    <div class="user-info">
      <p><strong>Email:</strong> <span id="userEmail"></span></p>
      <p><strong>Admin:</strong> <span id="userAdmin"></span></p>
      <p><strong>Status:</strong> <span style="color: #28a745;">Authenticated</span></p>
    </div>
    <button id="logoutBtn" style="margin-top: 15px;">Logout</button>
  </div>

  <script src="popup.js"></script>
</body>
</html>
```

### 4. Popup Script (popup.js)  
```javascript
document.addEventListener('DOMContentLoaded', async () => {
  const loginForm = document.getElementById('loginForm');
  const userInfo = document.getElementById('userInfo');
  const loginError = document.getElementById('loginError');
  const loginStatus = document.getElementById('loginStatus');
  const ssoLoginBtn = document.getElementById('ssoLoginBtn');

  // Check if already logged in
  const validation = await sendMessage({ action: 'validateToken' });
  
  if (validation.valid) {
    showUserInfo(validation.user);
  } else {
    showLoginForm();
  }

  // SSO Login button
  ssoLoginBtn.addEventListener('click', async () => {
    loginError.textContent = '';
    loginStatus.textContent = 'Opening SSO authentication...';
    ssoLoginBtn.disabled = true;
    ssoLoginBtn.textContent = 'Authenticating...';

    const result = await sendMessage({ action: 'loginSSO' });

    ssoLoginBtn.disabled = false;
    ssoLoginBtn.textContent = 'Login with SSO';
    loginStatus.textContent = '';

    if (result.success) {
      showUserInfo(result.user);
    } else {
      loginError.textContent = result.error || 'SSO authentication failed';
    }
  });

  // Logout button
  document.getElementById('logoutBtn').addEventListener('click', async () => {
    await sendMessage({ action: 'logout' });
    showLoginForm();
  });

  function showLoginForm() {
    loginForm.style.display = 'block';
    userInfo.style.display = 'none';
    loginError.textContent = '';
    loginStatus.textContent = '';
    ssoLoginBtn.disabled = false;
    ssoLoginBtn.textContent = 'Login with SSO';
  }

  function showUserInfo(user) {
    loginForm.style.display = 'none';
    userInfo.style.display = 'block';
    document.getElementById('userEmail').textContent = user.email;
    document.getElementById('userAdmin').textContent = user.admin ? 'Yes' : 'No';
  }

  function sendMessage(message) {
    return new Promise((resolve) => {
      chrome.runtime.sendMessage(message, resolve);
    });
  }
});
```

## Usage Examples

### Making API Calls from Content Script
```javascript
// content.js
async function makeApiCall() {
  const response = await chrome.runtime.sendMessage({
    action: 'apiCall',
    endpoint: '/chats',
    options: { method: 'GET' }
  });

  if (response.success) {
    console.log('Chats:', response.data);
  } else {
    console.error('API Error:', response.error);
  }
}
```

### Creating a New Chat
```javascript
async function createNewChat() {
  const response = await chrome.runtime.sendMessage({
    action: 'apiCall',
    endpoint: '/chats',
    options: {
      method: 'POST',
      body: JSON.stringify({
        chat: {
          assistant_id: 1, // Your assistant ID
          first_message: 'Hello from Chrome extension!'
        }
      })
    }
  });

  if (response.success) {
    console.log('Chat created:', response.data);
  }
}
```

## SSO Authentication Flow Details

### How It Works

1. **User clicks "Login with SSO"** in extension popup
2. **Extension opens new tab** to `/auth/get_token`
3. **Server checks authentication:**
   - If user already has SSO session → generates token immediately
   - If no session → redirects to SAML SSO login
4. **After SSO completion** → server generates API token and redirects to display page
5. **Token display page** → shows token and posts message to extension
6. **Extension captures token** → stores it securely and closes auth tab
7. **Extension uses token** → for all subsequent API calls

### Security Features

- **URL Fragment**: Token passed in URL fragment (`#token=...`) for security
- **Auto-cleanup**: Token removed from URL after extraction  
- **Origin verification**: Extension verifies message origin
- **Auto-close**: Auth window closes automatically after token capture
- **Token isolation**: Each extension gets its own token

## Security Considerations

1. **Token Storage**: API tokens are stored in Chrome's local storage, which is encrypted and isolated per extension
2. **HTTPS**: Always use HTTPS in production
3. **Token Expiration**: Implement token refresh if needed
4. **Extension ID**: In production, consider restricting CORS to specific extension IDs

## Troubleshooting

- **CORS Errors**: Check that your API server includes the `rack-cors` gem and proper configuration
- **401 Errors**: Token might be expired or invalid - the extension should handle re-authentication
- **Network Errors**: Verify API endpoint URLs and server availability

For more details, check the Rails API documentation and Chrome extension development guides.
