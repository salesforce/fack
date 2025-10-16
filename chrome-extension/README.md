# AI Chat Assistant Chrome Extension

A Chrome extension that provides a persistent AI chat interface through a side panel, integrated with your Rails application's SSO authentication.

## Features

- 🔐 **SSO Authentication**: Uses your existing SSO/SAML authentication system
- 💬 **AI Chat Interface**: Ask questions and get AI-generated responses in real-time
- 🤔 **Smart Responses**: Powered by your backend questions API with adaptive polling
- 📝 **Chat History**: Clean, scrollable conversation interface with timestamps
- 📌 **Persistent Side Panel**: Always accessible, stays open while browsing (Chrome 114+)
- 💾 **Secure Token Storage**: Stores authentication token securely in Chrome's local storage
- ⚙️ **Configurable URLs**: Set custom API and auth URLs for different environments
- 🔄 **Environment Switching**: Easy switching between dev, staging, and production
- 🚀 **Fast Responses**: Optimized polling stops immediately when answers are ready
- 🎯 **Clean UI**: Simplified interface with logout button and full-height scrolling

## Installation

1. **Load the Extension in Chrome:**
   - Open Chrome and go to `chrome://extensions/`
   - Enable "Developer mode" (toggle in top right)
   - Click "Load unpacked"
   - Select the `chrome-extension` folder from this project

2. **Configure API URLs:**
   - Open `background.js`
   - Update `API_BASE_URL` and `AUTH_BASE_URL` to match your server:
     ```javascript
     const API_BASE_URL = 'https://your-domain.com/api/v1'; // For production
     const AUTH_BASE_URL = 'https://your-domain.com'; // For production
     ```

## Usage

### 1. Open Side Panel

1. Click the extension icon in Chrome to open the persistent side panel
2. The side panel stays open while you browse different websites

### 2. Authentication

The extension uses Chrome's secure `chrome.identity.launchWebAuthFlow()` API for authentication:

1. Configure API URLs if needed (defaults to localhost:3000)
2. Click "🔐 Authenticate with SSO" 
3. Complete SSO login in a secure Chrome authentication window
4. Extension automatically captures and stores your API token via redirect
5. Authentication window closes automatically
6. Authentication section disappears, showing clean chat interface

**Authentication Flow:**
- Extension generates a secure Chrome extension redirect URI
- Opens your Rails SSO login page with the redirect URI
- After successful authentication, Rails redirects to the extension URI with the token
- Chrome automatically captures the token and closes the auth window
- More secure than tab-based authentication (no content script required)

### 3. Chat with AI

1. Type your question in the input area
2. Press "🚀 Ask Question" or Ctrl+Enter/Shift+Enter
3. Watch real-time status updates as AI processes your question
4. Get responses with full chat history and timestamps

### 4. Logout

- Click the red "Logout" button in the top header to end your session

## API Endpoints Used

The extension makes calls to these endpoints:

- `GET /auth/get_token` - SSO authentication for extensions
- `GET /auth/validate` - Validate current token
- `POST /api/v1/questions` - Submit questions to AI
- `GET /api/v1/questions/{id}` - Get question status and response

## Security Features

- **Chrome Identity API**: Uses secure `chrome.identity.launchWebAuthFlow()` for authentication
- **Secure Token Storage**: Uses Chrome's encrypted local storage
- **No Content Script Injection**: Token capture happens via secure redirect (no DOM access needed)
- **Automatic Window Closure**: Auth window closes automatically after token capture
- **Automatic Token Cleanup**: Clears invalid/expired tokens
- **HTTPS Support**: Ready for production HTTPS deployment
- **Legacy Fallback**: Maintains backward compatibility with content script flow

## Development

### File Structure
```
chrome-extension/
├── manifest.json          # Extension manifest with sidePanel configuration
├── background.js          # Service worker with API client and side panel handler
├── sidepanel.html        # Side panel UI (only interface)
├── sidepanel.js          # Side panel functionality and chat logic
├── content.js            # Content script for page integration
├── auth-content.js       # Auth-specific content script for token capture
├── chrome-version-check.js # Chrome version compatibility check
└── README.md             # This file
```

### Side Panel Interface

**📌 Persistent Side Panel (Chrome 114+ Required)**
- Always available - click the extension icon to open/close
- Stays open while you browse different websites and tabs
- Full-height chat scrolling with no container limits
- Clean header with logout button when authenticated
- Collapsible configuration section for easy setup
- No auto-close behavior - stays until you close it manually

### Chat Features

The AI chat interface provides:
- **Real-time Status Updates**: See AI processing stages (pending → processing → generating → completed)
- **Adaptive Polling**: Fast polling for quick responses, slower for complex questions
- **Status Indicators**: Visual feedback with timestamps and progress dots
- **Keyboard Shortcuts**: Ctrl+Enter or Shift+Enter to submit questions
- **Auto-scroll**: Chat automatically scrolls to show new messages
- **Clean History**: Timestamped conversation history with user/assistant message styling

### Customization

**Adding New Features:**
1. Add API methods to `DocumentAPI` class in `background.js`
2. Add message handlers in the `chrome.runtime.onMessage` listener
3. Add UI controls and handlers in `sidepanel.js`

**Styling:**
- Modify CSS in `sidepanel.html` `<style>` section
- Side panel adapts to browser width automatically
- Chat messages use responsive design

**Error Handling:**
- Comprehensive try/catch blocks for all operations
- Real-time error messages with specific details
- Automatic token cleanup on authentication failures
- Null checks prevent DOM access errors

## Troubleshooting

**Authentication Issues:**
- Check browser console for Chrome Identity API errors
- Ensure `redirect_uri` is properly handled by Rails controller
- Check that `/auth/get_token` endpoint is accessible
- Verify SSO/SAML configuration is working
- Check for "Chrome Identity Redirect URL" in background service worker console
- Ensure CORS is configured if using cross-origin requests
- If Chrome Identity API fails, extension falls back to legacy tab-based flow

**API Call Failures:**
- Check browser console for network errors
- Verify API endpoints are accessible
- Confirm authentication token is valid
- Use the test-api.html page to debug API calls

**Token Not Captured:**
- Check the auth tab's console for content script messages
- Verify the token appears in the page's data-token attribute
- Ensure the auth content script matches your domain in manifest.json
- Try refreshing the auth page if token doesn't appear

**Extension Not Loading:**
- Check Chrome's Extensions page for errors
- Ensure all files are present in the extension folder
- Verify manifest.json syntax is valid
- Make sure all required permissions are granted

## Production Deployment

1. **Configure URLs via Extension UI** (no code changes needed)
2. Test with production environment
3. Consider packaging as a .crx file for distribution
4. The manifest includes wildcard host permissions to work with any domain

**Environment-specific Setup:**
- **Development**: Use default `http://localhost:3000`
- **Staging**: Configure via UI: `https://staging-app.com`
- **Production**: Configure via UI: `https://your-app.com`

## Related Documentation

See the full Chrome extension integration guide in your Rails app at:
`docs/chrome-extension-integration.md`
