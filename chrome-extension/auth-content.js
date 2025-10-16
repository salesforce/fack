// Content script specifically for the auth/token pages
// This script captures the token from the auth page and forwards it to the service worker

console.log('Auth content script loaded for:', window.location.href);

let tokenSent = false;

// Function to extract token from the page
function extractTokenFromPage() {
  if (tokenSent) return null;
  
  // Check for token in data attribute (this contains the user email)
  const tokenDisplay = document.getElementById('token-display');
  if (tokenDisplay) {
    const token = tokenDisplay.getAttribute('data-token');
    if (token && token.length > 0) {
      console.log('Found token in data attribute');
      return token;
    }
  }
  
  return null;
}

// Function to send token to service worker
function sendTokenToServiceWorker(token) {
  if (tokenSent) return;
  
  console.log('Sending token to service worker');
  tokenSent = true;
  
  chrome.runtime.sendMessage({
    type: 'FACK_AUTH_TOKEN',
    success: true,
    token: token
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

// Note: The auth page handles postMessage communication directly, so no listener needed here

// Main initialization
function init() {
  console.log('Initializing auth content script');
  
  // Try to get token immediately
  if (checkForToken()) {
    return;
  }
  
  // If not found immediately, wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      setTimeout(() => checkForToken(), 100);
    });
  } else {
    // DOM is already ready, try again after a short delay
    setTimeout(() => checkForToken(), 100);
  }
}

// Start the initialization
init();
