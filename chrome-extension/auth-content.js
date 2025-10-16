// Content script for Chrome extension authentication
// 
// This script enables tab-based authentication flow:
//   1. Extension opens /auth/get_token in a new tab (background.js)
//   2. User logs in via SSO (if not already authenticated)
//   3. Rails renders the auth page with token in DOM (#token-display element)
//   4. This script extracts the token from the page
//   5. Sends token to background script via chrome.runtime.sendMessage()
//   6. Background script stores token and closes the auth tab
//
// This approach works everywhere (localhost, staging, production) and is
// simpler than chrome.identity.launchWebAuthFlow() which has limitations.

console.log('🔵 Auth content script loaded for:', window.location.href);
console.log('🔵 Document ready state:', document.readyState);

let tokenSent = false;

// Function to extract token from the page
function extractTokenFromPage() {
  if (tokenSent) {
    console.log('🔵 Token already sent, skipping');
    return null;
  }
  
  // Check for token in data attribute (this contains the user email)
  const tokenDisplay = document.getElementById('token-display');
  console.log('🔵 Looking for token-display element:', tokenDisplay);
  
  if (tokenDisplay) {
    const token = tokenDisplay.getAttribute('data-token');
    console.log('🔵 Token from data-token attribute:', token);
    
    if (token && token.length > 0) {
      console.log('✅ Found valid token:', token);
      return token;
    }
  }
  
  console.log('❌ No token found on page');
  return null;
}

// Function to send token to service worker
function sendTokenToServiceWorker(token) {
  if (tokenSent) {
    console.log('🔵 Token already sent, not sending again');
    return;
  }
  
  console.log('🚀 Sending token to service worker:', token);
  tokenSent = true;
  
  chrome.runtime.sendMessage({
    type: 'FACK_AUTH_TOKEN',
    success: true,
    token: token
  }, (response) => {
    console.log('✅ Message sent to background, response:', response);
  });
}

// Check for token immediately
function checkForToken() {
  const token = extractTokenFromPage();
  if (token) {
    sendTokenToServiceWorker(token);
    return true;
  }
  return false;
}

// Main initialization
function init() {
  console.log('Initializing auth content script');
  
  // Try to get token immediately
  if (checkForToken()) {
    return;
  }
  
  // Set up polling with multiple attempts
  let attempts = 0;
  const maxAttempts = 30; // 15 seconds total (500ms * 30)
  
  const pollForToken = () => {
    attempts++;
    console.log(`Polling for token, attempt ${attempts}/${maxAttempts}`);
    
    if (checkForToken() || attempts >= maxAttempts) {
      if (attempts >= maxAttempts && !tokenSent) {
        console.log('❌ Token polling timeout - token not found after 15 seconds');
      }
      return;
    }
    
    setTimeout(pollForToken, 500);
  };
  
  // Start polling immediately
  setTimeout(pollForToken, 100);
  
  // Also listen for DOM changes (Turbo redirects)
  document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM ready - checking for token again');
    setTimeout(() => checkForToken(), 100);
  });
  
  // Listen for Turbo redirects specifically  
  document.addEventListener('turbo:load', () => {
    console.log('Turbo load detected - checking for token again');
    setTimeout(() => checkForToken(), 100);
  });
}

// Start the initialization
init();
