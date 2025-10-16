class DocumentAPI {
  constructor() {
    this.token = null;
    this.baseUrl = 'http://localhost:3000'; // Default
    this.init();
  }

  async init() {
    // Load configuration from storage
    const result = await chrome.storage.local.get([
      'apiToken', 
      'baseUrl'
    ]);
    
    this.token = result.apiToken;
    this.baseUrl = result.baseUrl || 'http://localhost:3000';
  }

  async updateConfiguration(baseUrl) {
    // Validate URL
    try {
      new URL(baseUrl);
    } catch (error) {
      throw new Error('Invalid URL format');
    }

    // Request permission for this URL
    const urlPattern = `${new URL(baseUrl).origin}/*`;
    console.log('🔐 Requesting permission for:', urlPattern);
    
    const granted = await chrome.permissions.request({
      origins: [urlPattern]
    });
    
    if (!granted) {
      throw new Error('Permission denied. Please allow access to this URL.');
    }
    
    console.log('✅ Permission granted for:', urlPattern);

    this.baseUrl = baseUrl;
    
    await chrome.storage.local.set({
      baseUrl: this.baseUrl
    });
  }

  getConfiguration() {
    return {
      baseUrl: this.baseUrl
    };
  }

  async authenticateWithSSO() {
    // Always use tab-based authentication - it's simpler and works everywhere
    console.log('🔐 Using tab-based authentication');
    return this.authenticateWithTab();
    
    // Note: chrome.identity.launchWebAuthFlow() is available but not used
    // because the tab-based flow is more flexible and easier to debug.
    // If you need chrome.identity flow, use authenticateWithChromeIdentity() instead.
  }

  async authenticateWithTab() {
    return new Promise((resolve) => {
      // Open SSO authentication tab (original working method for localhost)
      const authUrl = `${this.baseUrl}/auth/get_token`;
      console.log('Opening auth tab:', authUrl);
      
      chrome.tabs.create({
        url: authUrl,
        active: true
      }, async (tab) => {
        const authTabId = tab.id;
        let resolved = false;
        console.log('Auth tab created with ID:', authTabId);

        // Wait for page to load, then inject the auth content script
        chrome.tabs.onUpdated.addListener(function listener(tabId, changeInfo) {
          if (tabId === authTabId && changeInfo.status === 'complete') {
            console.log('Auth page loaded, injecting content script...');
            
            // Inject the auth content script manually
            chrome.scripting.executeScript({
              target: { tabId: authTabId },
              files: ['auth-content.js']
            }).then(() => {
              console.log('✅ Auth content script injected successfully');
            }).catch((error) => {
              console.error('❌ Failed to inject auth content script:', error);
            });
            
            // Remove this listener after first execution
            chrome.tabs.onUpdated.removeListener(listener);
          }
        });

        // Listen for messages from the auth tab
        const messageListener = (message, sender, sendResponse) => {
          console.log('Background received message:', message, 'from tab:', sender.tab?.id);
          
          // Only handle messages from our auth tab
          if (sender.tab?.id !== authTabId) {
            console.log('Message not from auth tab, ignoring');
            return;
          }

          if (message.type === 'FACK_AUTH_TOKEN' && message.success && !resolved) {
            resolved = true;
            console.log('✅ Token received from auth tab:', message.token);
            
            // Store token
            this.token = message.token;
            chrome.storage.local.set({ 
              apiToken: this.token 
            }).then(() => {
              console.log('Token stored, cleaning up and closing tab');
              // Clean up
              chrome.runtime.onMessage.removeListener(messageListener);
              chrome.tabs.onRemoved.removeListener(tabRemovedListener);
              chrome.tabs.remove(authTabId);
              resolve({ success: true, token: this.token });
            });
          }
        };

        // Listen for tab closure
        const tabRemovedListener = (tabId) => {
          if (tabId === authTabId && !resolved) {
            resolved = true;
            console.log('Auth tab closed before authentication completed');
            chrome.runtime.onMessage.removeListener(messageListener);
            chrome.tabs.onRemoved.removeListener(tabRemovedListener);
            resolve({ success: false, error: 'Authentication cancelled' });
          }
        };

        // Add listeners
        chrome.runtime.onMessage.addListener(messageListener);
        chrome.tabs.onRemoved.addListener(tabRemovedListener);
        console.log('Listeners added, waiting for token...');

        // Timeout after 5 minutes
        setTimeout(() => {
          if (!resolved) {
            resolved = true;
            console.log('❌ Authentication timeout after 5 minutes');
            chrome.runtime.onMessage.removeListener(messageListener);
            chrome.tabs.onRemoved.removeListener(tabRemovedListener);
            chrome.tabs.remove(authTabId).catch(() => {}); // Tab might already be closed
            resolve({ success: false, error: 'Authentication timeout' });
          }
        }, 300000);
      });
    });
  }

  async validateToken() {
    if (!this.token) return { valid: false };

    try {
      const response = await fetch(`${this.baseUrl}/auth/validate`, {
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
    this.token = null;
    await chrome.storage.local.clear();
  }

  async makeAPICall(endpoint, options = {}) {
    if (!this.token) {
      throw new Error('Not authenticated');
    }

    const url = `${this.baseUrl}/api/v1${endpoint}`;
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

    if (!response.ok) {
      throw new Error(`API call failed: ${response.status} ${response.statusText}`);
    }

    return response.json();
  }

  // Question-specific methods
  async createQuestion(question, libraryId = null) {
    const payload = {
      question: {
        question: question
      }
    };
    if (libraryId) {
      payload.question.library_id = libraryId;
    }
    
    console.log('Creating question with payload:', payload);
    
    try {
      const result = await this.makeAPICall('/questions', {
        method: 'POST',
        body: JSON.stringify(payload)
      });
      console.log('Question created:', result);
      return result;
    } catch (error) {
      console.error('Failed to create question:', error);
      throw error;
    }
  }

  async getQuestion(id) {
    return this.makeAPICall(`/questions/${id}`);
  }

  async getQuestionWithPolling(id, maxAttempts = 60, interval = 1000) {
    console.log(`Starting polling for question ${id}, max attempts: ${maxAttempts}`);
    
    // Use consistent 2-second polling interval
    const getInterval = (attempt) => {
      return 3000; // All attempts: 2s (consistent)
    };
    
    for (let attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        const question = await this.getQuestion(id);
        console.log(`Polling attempt ${attempt + 1}/${maxAttempts}:`, {
          status: question.status, 
          hasAnswer: !!question.answer,
          timestamp: new Date().toLocaleTimeString()
        });
        
        // Check if answer is ready
        if (question.status === 'completed' && question.answer) {
          console.log('Question completed with answer');
          return question;
        }
        
        // Check if answer is generated (should stop polling)
        if (question.status === 'generated' && question.answer) {
          console.log('Question generated with answer');
          return question;
        }
        
        // Also stop if status is generated even without answer (edge case)
        if (question.status === 'generated') {
          console.log('Question status is generated, stopping polling');
          return question;
        }
        
        // Check for failed status
        if (question.status === 'failed' || question.status === 'error') {
          console.log('Question failed:', question.status);
          return question;
        }
        
        // Wait before next attempt (except on last attempt)
        if (attempt < maxAttempts - 1) {
          const waitTime = getInterval(attempt);
          console.log(`Waiting ${waitTime}ms before next attempt...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
        }
      } catch (error) {
        console.error(`Polling attempt ${attempt + 1} failed:`, error);
        // Continue polling unless it's the last attempt
        if (attempt === maxAttempts - 1) {
          throw error;
        }
        const waitTime = getInterval(attempt);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }
    
    // Return the question even if not completed (timeout)
    console.log('Polling timed out, returning final state');
    return this.getQuestion(id);
  }
}

// Global API client instance
const documentAPI = new DocumentAPI();

// Handle extension icon click - open side panel
chrome.action.onClicked.addListener((tab) => {
  chrome.sidePanel.open({ tabId: tab.id }).catch((error) => {
    console.error('Failed to open side panel:', error);
    // Fallback: try opening without tabId for newer Chrome versions
    chrome.sidePanel.open({ windowId: tab.windowId }).catch((fallbackError) => {
      console.error('Fallback also failed:', fallbackError);
    });
  });
});

// Message handling for popup and content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  (async () => {
    try {
      switch (request.action) {
        case 'sendToChat':
          // Handle text from content script
          console.log('Background: Received text from content script:', request.text);
          
          try {
            // Store in storage for side panel to retrieve
            await chrome.storage.local.set({
              pendingChatText: {
                text: request.text,
                source: request.source,
                timestamp: Date.now()
              }
            });
            
            console.log('Background: Text stored in chrome.storage.local');
            sendResponse({ success: true, message: 'Text stored for chat' });
            
            // Try to send direct message to side panel if it's listening
            try {
              chrome.runtime.sendMessage({
                action: 'addTextToChat',
                text: request.text,
                source: request.source
              }).catch(() => {
                console.log('Background: Side panel not currently open, text stored for later');
              });
            } catch (e) {
              console.log('Background: Side panel not available, text stored for when it opens');
            }
            
          } catch (error) {
            console.error('Background: Error handling sendToChat:', error);
            sendResponse({ success: false, error: error.message });
          }
          break;
        case 'authenticate':
          const authResult = await documentAPI.authenticateWithSSO();
          sendResponse(authResult);
          break;
          
        case 'validateToken':
          const validation = await documentAPI.validateToken();
          sendResponse(validation);
          break;
          
        case 'logout':
          await documentAPI.logout();
          sendResponse({ success: true });
          break;
          
        case 'createQuestion':
          const newQuestion = await documentAPI.createQuestion(request.question, request.libraryId);
          sendResponse({ success: true, data: newQuestion });
          break;
          
        case 'getQuestion':
          const question = await documentAPI.getQuestion(request.id);
          sendResponse({ success: true, data: question });
          break;
          
        case 'getQuestionWithPolling':
          const completedQuestion = await documentAPI.getQuestionWithPolling(request.id, request.maxAttempts, request.interval);
          sendResponse({ success: true, data: completedQuestion });
          break;

        case 'getConfiguration':
          const config = documentAPI.getConfiguration();
          sendResponse({ success: true, data: config });
          break;

        case 'updateConfiguration':
          await documentAPI.updateConfiguration(request.baseUrl);
          sendResponse({ success: true });
          break;

        // Remove the openSidePanel case since it needs to be called directly from popup
        // due to user gesture requirements
          
        default:
          sendResponse({ success: false, error: 'Unknown action' });
      }
    } catch (error) {
      sendResponse({ success: false, error: error.message });
    }
  })();
  
  return true; // Keep message channel open for async response
});
