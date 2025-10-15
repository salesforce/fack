console.log('AI Chat Assistant content script loaded');

// Global state with namespace to avoid conflicts
const AIChatAssistant = {
  isActive: false,
  overlay: null,
  selectedText: '',
  selectionTimeout: null,
  initialized: false
};

// Wait for DOM to be ready to avoid conflicts
function initializeExtension() {
  if (AIChatAssistant.initialized) return;
  
  console.log('Initializing AI Chat Assistant extension');
  AIChatAssistant.initialized = true;

  // Listen for text selection to capture highlighted text
  document.addEventListener('mouseup', handleTextSelection, { passive: true });
  document.addEventListener('keyup', handleTextSelection, { passive: true });
  document.addEventListener('keydown', handleKeyboardShortcuts, { passive: false });
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeExtension);
} else {
  // DOM already loaded
  setTimeout(initializeExtension, 100); // Small delay to avoid conflicts
}

function handleTextSelection(event) {
  try {
    // Clear any existing timeout
    if (AIChatAssistant.selectionTimeout) {
      clearTimeout(AIChatAssistant.selectionTimeout);
    }

    // Debounce the selection to avoid too many rapid calls
    AIChatAssistant.selectionTimeout = setTimeout(() => {
      try {
        const selection = window.getSelection();
        if (!selection) return;
        
        const text = selection.toString().trim();
        
        if (text.length > 0) {
          AIChatAssistant.selectedText = text;
          console.log('AI Chat Assistant: Text selected:', text.substring(0, 50) + '...');
          
          // Show a small indicator that text was captured
          showSelectionIndicator(text);
        }
      } catch (error) {
        console.error('AI Chat Assistant: Error in text selection:', error);
      }
    }, 300);
  } catch (error) {
    console.error('AI Chat Assistant: Error in handleTextSelection:', error);
  }
}

function showSelectionIndicator(text) {
  try {
    // Remove any existing indicator
    const existingIndicator = document.getElementById('ai-chat-ext-selection-indicator');
    if (existingIndicator) {
      existingIndicator.remove();
    }

    // Only show indicator for text longer than 5 characters
    if (text.length < 5) return;

    // Create indicator
    const indicator = document.createElement('div');
    indicator.id = 'ai-chat-ext-selection-indicator';
  indicator.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    background: #007cba;
    color: white;
    padding: 8px 12px;
    border-radius: 6px;
    font-size: 12px;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    z-index: 10000;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    cursor: pointer;
    max-width: 300px;
    word-wrap: break-word;
    animation: slideIn 0.3s ease;
  `;
  
  // Add CSS animation
  const style = document.createElement('style');
  style.textContent = `
    @keyframes slideIn {
      from { transform: translateX(100%); opacity: 0; }
      to { transform: translateX(0); opacity: 1; }
    }
  `;
  document.head.appendChild(style);
  
  const truncatedText = text.length > 50 ? text.substring(0, 50) + '...' : text;
  indicator.innerHTML = `
    <div style="font-weight: bold; margin-bottom: 4px;">✨ Text Captured</div>
    <div style="opacity: 0.9; margin-bottom: 6px;">"${escapeHtml(truncatedText)}"</div>
    <div style="font-size: 10px; opacity: 0.7;">Click to send to AI chat</div>
  `;
  
  // Add click handler to send to chat
  indicator.addEventListener('click', () => {
    sendToChat(text);
    indicator.remove();
  });
  
  document.body.appendChild(indicator);
  
  // Auto-remove after 5 seconds
  setTimeout(() => {
    if (indicator && indicator.parentNode) {
      indicator.style.animation = 'slideIn 0.3s ease reverse';
      setTimeout(() => {
        if (indicator.parentNode) {
          indicator.remove();
        }
      }, 300);
    }
    }, 5000);
  } catch (error) {
    console.error('AI Chat Assistant: Error showing selection indicator:', error);
  }
}

function sendToChat(text) {
  try {
    // Check if extension context is still valid
    if (!chrome.runtime?.id) {
      console.warn('AI Chat Assistant: Extension context invalidated. Please refresh the page.');
      showNotification('Extension reloaded. Please refresh this page to continue using text selection.', 'error');
      return;
    }

    // Send the selected text to the side panel
    chrome.runtime.sendMessage({
      action: 'sendToChat',
      text: text,
      source: window.location.href
    }, (response) => {
      if (chrome.runtime.lastError) {
        console.error('AI Chat Assistant: Error sending to chat:', chrome.runtime.lastError);
        
        // Check if it's a context invalidation error
        if (chrome.runtime.lastError.message?.includes('context invalidated') || 
            chrome.runtime.lastError.message?.includes('Extension context')) {
          showNotification('Extension reloaded. Please refresh this page to continue using text selection.', 'error');
        } else {
          showNotification('Failed to send text to chat. Please try again.', 'error');
        }
      } else {
        console.log('AI Chat Assistant: Text sent to chat:', response);
        
        // Show success notification
        showNotification('Text sent to AI chat!', 'success');
      }
    });
  } catch (error) {
    console.error('AI Chat Assistant: Error in sendToChat:', error);
    
    if (error.message?.includes('Extension context invalidated') || 
        error.message?.includes('context invalidated')) {
      showNotification('Extension reloaded. Please refresh this page to continue using text selection.', 'error');
    } else {
      showNotification('Failed to send text to chat. Please try again.', 'error');
    }
  }
}

function showNotification(message, type = 'info') {
  try {
    const notification = document.createElement('div');
  notification.style.cssText = `
    position: fixed;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: ${type === 'success' ? '#28a745' : '#007cba'};
    color: white;
    padding: 8px 16px;
    border-radius: 6px;
    font-size: 12px;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    z-index: 10001;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    animation: fadeInOut 2s ease;
  `;
  
  notification.textContent = message;
  document.body.appendChild(notification);
  
  // Add fade in/out animation
  const style = document.createElement('style');
  style.textContent = `
    @keyframes fadeInOut {
      0% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
      20%, 80% { opacity: 1; transform: translateX(-50%) translateY(0); }
      100% { opacity: 0; transform: translateX(-50%) translateY(-10px); }
    }
  `;
  document.head.appendChild(style);
  
  setTimeout(() => {
    if (notification.parentNode) {
      notification.remove();
    }
    if (style.parentNode) {
      style.remove();
    }
    }, 2000);
  } catch (error) {
    console.error('AI Chat Assistant: Error showing notification:', error);
  }
}

// Utility function to escape HTML
function escapeHtml(unsafe) {
  if (!unsafe) return '';
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function handleKeyboardShortcuts(e) {
  try {
    // Check if extension context is still valid
    if (!chrome.runtime?.id) {
      console.warn('AI Chat Assistant: Extension context invalidated during keyboard shortcut');
      return;
    }

    // Ctrl+Shift+C to send page content to chat
    if (e.ctrlKey && e.shiftKey && e.key === 'C') {
      e.preventDefault();
      const pageText = document.body?.innerText?.substring(0, 1000) || ''; // First 1000 characters
      if (pageText.trim()) {
        sendToChat(pageText);
        // Don't show notification here since sendToChat will handle it
      }
    }
  } catch (error) {
    console.error('AI Chat Assistant: Error in keyboard shortcut handler:', error);
  }
}

console.log('AI Chat Assistant content script ready. Select text to send to chat, or press Ctrl+Shift+C to send page content.');