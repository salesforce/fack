// Optional content script for interacting with web pages
// This demonstrates how to use the extension API from a content script

// Example: Extract text from current page and find similar documents
async function findSimilarToPageContent() {
  // Get some text from the current page
  const pageText = document.body.innerText.substring(0, 500); // First 500 characters
  
  try {
    const response = await chrome.runtime.sendMessage({
      action: 'getSimilarDocuments',
      text: pageText
    });
    
    if (response.success) {
      console.log('Similar documents found:', response.data);
      
      // You could display results in a popup or notification
      // For example, create a floating div with results
      displaySimilarDocuments(response.data);
    } else {
      console.error('Failed to find similar documents:', response.error);
    }
  } catch (error) {
    console.error('Error finding similar documents:', error);
  }
}

// Example: Search for documents based on selected text
function handleTextSelection() {
  document.addEventListener('mouseup', async () => {
    const selectedText = window.getSelection().toString().trim();
    
    if (selectedText.length > 10) { // Only search if substantial text is selected
      try {
        const response = await chrome.runtime.sendMessage({
          action: 'searchDocuments',
          query: selectedText
        });
        
        if (response.success) {
          console.log('Search results:', response.data);
          // You could show a tooltip or popup with results
          showSearchResults(selectedText, response.data);
        }
      } catch (error) {
        console.error('Search error:', error);
      }
    }
  });
}

// Display similar documents in a floating overlay
function displaySimilarDocuments(documents) {
  // Remove existing overlay
  const existingOverlay = document.getElementById('doc-finder-overlay');
  if (existingOverlay) {
    existingOverlay.remove();
  }
  
  if (!documents || documents.length === 0) {
    return;
  }
  
  // Create overlay
  const overlay = document.createElement('div');
  overlay.id = 'doc-finder-overlay';
  overlay.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    width: 300px;
    max-height: 400px;
    background: white;
    border: 1px solid #ccc;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    z-index: 10000;
    font-family: Arial, sans-serif;
    font-size: 14px;
    overflow: hidden;
  `;
  
  // Create content
  const content = `
    <div style="padding: 15px; border-bottom: 1px solid #eee; background: #f8f9fa;">
      <div style="font-weight: bold; margin-bottom: 5px;">📄 Similar Documents</div>
      <button onclick="this.closest('#doc-finder-overlay').remove()" 
              style="position: absolute; top: 10px; right: 10px; background: none; border: none; font-size: 18px; cursor: pointer;">×</button>
    </div>
    <div style="padding: 10px; max-height: 320px; overflow-y: auto;">
      ${documents.slice(0, 5).map(doc => `
        <div style="padding: 8px; margin: 4px 0; background: #f5f5f5; border-radius: 4px; border-left: 3px solid #007cba;">
          <div style="font-weight: bold; margin-bottom: 4px;">${escapeHtml(doc.title || 'Untitled')}</div>
          <div style="font-size: 12px; color: #666;">
            ${doc.library?.name || 'Unknown Library'}
          </div>
          ${doc.url ? `<a href="${escapeHtml(doc.url)}" target="_blank" style="font-size: 12px; color: #007cba;">View Document</a>` : ''}
        </div>
      `).join('')}
    </div>
  `;
  
  overlay.innerHTML = content;
  document.body.appendChild(overlay);
  
  // Auto-remove after 10 seconds
  setTimeout(() => {
    if (overlay.parentNode) {
      overlay.remove();
    }
  }, 10000);
}

// Show search results in a temporary notification
function showSearchResults(query, documents) {
  // Create a simple notification
  const notification = document.createElement('div');
  notification.style.cssText = `
    position: fixed;
    top: 50px;
    right: 20px;
    background: #28a745;
    color: white;
    padding: 12px 16px;
    border-radius: 6px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
    z-index: 10000;
    font-family: Arial, sans-serif;
    font-size: 14px;
    max-width: 300px;
  `;
  
  const docCount = Array.isArray(documents) ? documents.length : (documents.documents?.length || 0);
  notification.textContent = `Found ${docCount} document${docCount !== 1 ? 's' : ''} for "${query.substring(0, 30)}${query.length > 30 ? '...' : ''}"`;
  
  document.body.appendChild(notification);
  
  // Remove after 3 seconds
  setTimeout(() => {
    if (notification.parentNode) {
      notification.remove();
    }
  }, 3000);
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

// Example: Add keyboard shortcut to find similar documents
document.addEventListener('keydown', (e) => {
  // Ctrl+Shift+F to find similar documents
  if (e.ctrlKey && e.shiftKey && e.key === 'F') {
    e.preventDefault();
    findSimilarToPageContent();
  }
});

// Initialize text selection handler
// Uncomment the line below if you want automatic search on text selection
// handleTextSelection();

console.log('Document Finder content script loaded. Press Ctrl+Shift+F to find similar documents.');
