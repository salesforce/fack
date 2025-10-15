// Content script specifically for the auth/token pages
// This script captures the token from the auth page and forwards it to the service worker

console.log('Auth content script loaded for:', window.location.href);

let tokenSent = false;

// Function to extract token from the page
function extractTokenFromPage() {
  if (tokenSent) return null;
  
  // Method 1: Check for token in data attribute (primary method)
  const tokenDisplay = document.getElementById('token-display');
  if (tokenDisplay) {
    const token = tokenDisplay.getAttribute('data-token');
    if (token && token.length > 10) { // Basic validation
      console.log('Found token in data attribute');
      return token;
    }
  }
  
  // Method 2: Check for token in the text content
  if (tokenDisplay && tokenDisplay.textContent) {
    const textContent = tokenDisplay.textContent.trim();
    // Look for a token-like string (alphanumeric, length > 20)
    if (textContent.length > 20 && /^[a-zA-Z0-9_-]+$/.test(textContent)) {
      console.log('Found token in text content');
      return textContent;
    }
  }
  
  // Method 3: Check URL hash for token
  const hash = window.location.hash;
  if (hash && hash.includes('token=')) {
    const tokenMatch = hash.match(/token=([^&]+)/);
    if (tokenMatch) {
      console.log('Found token in URL hash');
      return tokenMatch[1];
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
  
  // Clean up URL hash if it was used
  if (window.location.hash.includes('token=')) {
    window.location.hash = '';
  }
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

// Listen for window postMessage events (backup method)
window.addEventListener('message', (event) => {
  console.log('Auth content script received message:', event.data);
  
  if (event.data.type === 'FACK_AUTH_TOKEN' && event.data.success && !tokenSent) {
    console.log('Forwarding auth token from postMessage to service worker');
    sendTokenToServiceWorker(event.data.token);
  }
});

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
  
  // Set up polling to check for token periodically
  let attempts = 0;
  const maxAttempts = 50; // 25 seconds total (500ms * 50)
  
  const tokenCheckInterval = setInterval(() => {
    attempts++;
    
    if (checkForToken() || attempts >= maxAttempts) {
      clearInterval(tokenCheckInterval);
      if (attempts >= maxAttempts && !tokenSent) {
        console.log('Token check timeout - no token found');
      }
    }
  }, 500);
}

// Start the initialization
init();

// Also listen for dynamic content changes (in case token is loaded via AJAX)
const observer = new MutationObserver((mutations) => {
  if (tokenSent) {
    observer.disconnect();
    return;
  }
  
  mutations.forEach((mutation) => {
    if (mutation.type === 'childList' || mutation.type === 'attributes') {
      if (checkForToken()) {
        observer.disconnect();
      }
    }
  });
});

// Start observing
if (document.body) {
  observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['data-token']
  });
} else {
  document.addEventListener('DOMContentLoaded', () => {
    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['data-token']
    });
  });
}
