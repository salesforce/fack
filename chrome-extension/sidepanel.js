// Side panel script - same functionality as popup but persistent
console.log('Side panel loaded');

document.addEventListener('DOMContentLoaded', async () => {
  // DOM elements
  const loginForm = document.getElementById('loginForm');
  const loginSection = document.getElementById('loginSection');
  const headerBar = document.getElementById('headerBar');
  const chatSection = document.getElementById('chatSection');
  const authError = document.getElementById('authError');
  const authStatus = document.getElementById('authStatus');
  const authBtn = document.getElementById('authBtn');
  const logoutBtn = document.getElementById('logoutBtn');
  
  const askBtn = document.getElementById('askBtn');
  const questionInput = document.getElementById('questionInput');
  const chatHistory = document.getElementById('chatHistory');
  const actionStatus = document.getElementById('actionStatus');
  const actionError = document.getElementById('actionError');
  const clearChatBtn = document.getElementById('clearChatBtn');
  
  const saveConfigBtn = document.getElementById('saveConfigBtn');
  const baseUrlInput = document.getElementById('baseUrlInput');
  const configStatus = document.getElementById('configStatus');
  const configError = document.getElementById('configError');
  const configToggle = document.getElementById('configToggle');
  const configContent = document.getElementById('configContent');

  // Load configuration and check authentication status on load
  await loadConfiguration();
  await checkAuthStatus();
  
  // Check for pending chat text from content scripts
  await checkPendingChatText();

  // Listen for messages from content scripts
  chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'addTextToChat') {
      addTextFromContentScript(request.text, request.source);
      sendResponse({ success: true });
    }
  });

  // Event listeners - with null checks
  if (authBtn) authBtn.addEventListener('click', authenticate);
  if (logoutBtn) logoutBtn.addEventListener('click', logout);
  if (askBtn) askBtn.addEventListener('click', askQuestion);
  if (clearChatBtn) clearChatBtn.addEventListener('click', clearChatHistory);
  if (saveConfigBtn) saveConfigBtn.addEventListener('click', saveConfiguration);

  // Configuration section toggle
  if (configToggle && configContent) {
    configToggle.addEventListener('click', () => {
      const isExpanded = configContent.classList.contains('expanded');
      if (isExpanded) {
        configContent.classList.remove('expanded');
        configContent.classList.add('collapsed');
        configToggle.textContent = '+';
      } else {
        configContent.classList.remove('collapsed');
        configContent.classList.add('expanded');
        configToggle.textContent = '−';
      }
    });
  }

  // Enter key support for question input (Ctrl+Enter or Shift+Enter to submit)
  if (questionInput) {
    questionInput.addEventListener('keypress', (e) => {
      if ((e.ctrlKey || e.shiftKey) && e.key === 'Enter') {
        e.preventDefault();
        askQuestion();
      }
    });
  }

  async function checkAuthStatus() {
    const validation = await sendMessage({ action: 'validateToken' });
    
    if (validation && validation.valid) {
      showAuthenticatedState();
    } else {
      showUnauthenticatedState();
    }
  }

  async function authenticate() {
    clearMessages();
    setButtonState(authBtn, 'Authenticating...', true);
    authStatus.textContent = 'Opening SSO authentication...';

    try {
      const result = await sendMessage({ action: 'authenticate' });

      setButtonState(authBtn, '🔐 Authenticate with SSO', false);
      
      if (result && result.success) {
        showAuthenticatedState();
        authStatus.textContent = 'Successfully authenticated!';
      } else {
        showUnauthenticatedState();
        authError.textContent = result?.error || 'Authentication failed';
      }
    } catch (error) {
      setButtonState(authBtn, '🔐 Authenticate with SSO', false);
      showUnauthenticatedState();
      authError.textContent = 'Authentication error: ' + error.message;
    }
  }

  async function logout() {
    await sendMessage({ action: 'logout' });
    showUnauthenticatedState();
  }

  async function askQuestion() {
    const question = questionInput.value.trim();
    if (!question) {
      actionError.textContent = 'Please enter a question';
      return;
    }
    
    clearActionMessages();
    
    // Add user message to chat
    addUserMessage(question);
    
    // Clear input
    questionInput.value = '';
    
    // Disable ask button
    askBtn.disabled = true;
    askBtn.innerHTML = '<span class="thinking-icon">✨</span> Thinking...';
    
    // Add loading message
    const loadingId = addLoadingMessage();
    
    try {
      // Get current page context
      const pageContext = await getCurrentPageContext();
      
      // Append page context to question
      const questionWithContext = `${question}

---
Context:
Page: ${pageContext.title}
URL: ${pageContext.url}`;
      
      // Create question
      console.log('Creating question with context:', questionWithContext);
      const result = await sendMessage({ 
        action: 'createQuestion', 
        question: questionWithContext 
      });
      
      console.log('Create question result:', result);
      
      if (result && result.success) {
        // Remove loading message
        removeMessage(loadingId);
        
        console.log('Polling for answer, question ID:', result.data.id);
        
        // Poll for answer with 2-second polling
        const completedQuestion = await sendMessage({
          action: 'getQuestionWithPolling',
          id: result.data.id,
          maxAttempts: 60,
          interval: 3000
        });
        
        console.log('Polling result:', completedQuestion);
        
        if (completedQuestion && completedQuestion.success) {
          if (completedQuestion.data.answer) {
            addAssistantMessage(completedQuestion.data.answer);
          } else {
            console.log('Question status:', completedQuestion.data.status);
            addAssistantMessage(`I'm still working on your answer. Status: ${completedQuestion.data.status || 'processing'}`);
          }
        } else {
          const errorMsg = completedQuestion?.error || 'Unknown polling error';
          console.error('Polling failed:', errorMsg);
          addAssistantMessage(`Sorry, there was an error getting your answer: ${errorMsg}`);
        }
      } else {
        removeMessage(loadingId);
        const errorMsg = result?.error || 'Failed to ask question';
        console.error('Create question failed:', errorMsg);
        actionError.textContent = errorMsg;
        addAssistantMessage(`Sorry, I couldn't process your question: ${errorMsg}`);
      }
    } catch (error) {
      removeMessage(loadingId);
      console.error('Ask question error:', error);
      actionError.textContent = 'Error: ' + error.message;
      addAssistantMessage("Sorry, there was an error: " + error.message);
    } finally {
      // Re-enable ask button
      askBtn.disabled = false;
      askBtn.innerHTML = '🚀 Ask Question';
    }
  }

  function addUserMessage(message) {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'chat-message user-message';
    messageDiv.innerHTML = `
      <div>${escapeHtml(message)}</div>
      <div class="message-timestamp">${new Date().toLocaleTimeString()}</div>
    `;
    chatHistory.appendChild(messageDiv);
    scrollChatToBottom();
  }

  function addAssistantMessage(message) {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'chat-message assistant-message';
    messageDiv.innerHTML = `
      <div class="markdown-content">${formatMarkdown(message)}</div>
      <div class="message-timestamp">${new Date().toLocaleTimeString()}</div>
    `;
    chatHistory.appendChild(messageDiv);
    scrollChatToBottom();
  }

  function clearChatHistory() {
    if (confirm('Are you sure you want to clear the chat history?')) {
      chatHistory.innerHTML = '';
      actionStatus.textContent = 'Chat history cleared';
      setTimeout(() => {
        actionStatus.textContent = '';
      }, 2000);
    }
  }

  // Simple markdown formatter
  function formatMarkdown(text) {
    if (!text) return '';
    
    // Escape HTML first to prevent XSS
    text = text.replace(/&/g, '&amp;')
               .replace(/</g, '&lt;')
               .replace(/>/g, '&gt;');
    
    // Code blocks (```code```)
    text = text.replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>');
    
    // Inline code (`code`)
    text = text.replace(/`([^`]+)`/g, '<code>$1</code>');
    
    // Headers - add markers to split lists later
    text = text.replace(/^### (.*$)/gm, '<!--HEADING--><h3>$1</h3><!--/HEADING-->');
    text = text.replace(/^## (.*$)/gm, '<!--HEADING--><h2>$1</h2><!--/HEADING-->');
    text = text.replace(/^# (.*$)/gm, '<!--HEADING--><h1>$1</h1><!--/HEADING-->');
    
    // Bold (**bold** or __bold__)
    text = text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    text = text.replace(/__(.*?)__/g, '<strong>$1</strong>');
    
    // Italic (*italic* or _italic_)
    text = text.replace(/\*(.*?)\*/g, '<em>$1</em>');
    text = text.replace(/_(.*?)_/g, '<em>$1</em>');
    
    // Convert list items but don't wrap in ul/ol yet
    text = text.replace(/^[\s]*[-\*\+]\s+(.+)$/gm, '<!--UL_ITEM--><li>$1</li>');
    text = text.replace(/^[\s]*\d+\.\s+(.+)$/gm, '<!--OL_ITEM--><li>$1</li>');
    
    // Now process the text to create separate lists after headings
    text = processListsWithHeadings(text);
    
    // Links [text](url) and (text)[url] formats
    text = text.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
    text = text.replace(/\(([^\)]+)\)\[([^\]]+)\]/g, '<a href="$2" target="_blank" rel="noopener">$1</a>');
    
    // Clean up markers
    text = text.replace(/<!--HEADING-->|<!--\/HEADING-->/g, '');
    
    // Line breaks
    text = text.replace(/\n\n/g, '</p><p>');
    text = text.replace(/\n/g, '<br>');
    
    // Wrap in paragraphs
    if (!text.includes('<p>') && !text.includes('<h1>') && !text.includes('<h2>') && !text.includes('<h3>')) {
      text = '<p>' + text + '</p>';
    }
    
    return text;
  }

  function processListsWithHeadings(text) {
    // Split text by headings to process each section separately
    const sections = text.split(/(<!--HEADING-->.*?<!--\/HEADING-->)/);
    
    for (let i = 0; i < sections.length; i++) {
      // Skip heading sections themselves
      if (sections[i].includes('<!--HEADING-->')) continue;
      
      // Process unordered lists in this section
      let section = sections[i];
      const ulItems = section.match(/<!--UL_ITEM--><li>.*?<\/li>/g);
      if (ulItems && ulItems.length > 0) {
        const ulList = '<ul>' + ulItems.map(item => item.replace('<!--UL_ITEM-->', '')).join('') + '</ul>';
        section = section.replace(/<!--UL_ITEM--><li>.*?<\/li>/g, '');
        section = section + ulList;
      }
      
      // Process ordered lists in this section
      const olItems = section.match(/<!--OL_ITEM--><li>.*?<\/li>/g);
      if (olItems && olItems.length > 0) {
        const olList = '<ol>' + olItems.map(item => item.replace('<!--OL_ITEM-->', '')).join('') + '</ol>';
        section = section.replace(/<!--OL_ITEM--><li>.*?<\/li>/g, '');
        section = section + olList;
      }
      
      sections[i] = section;
    }
    
    return sections.join('');
  }

  function addLoadingMessage() {
    const messageId = 'loading-' + Date.now();
    const messageDiv = document.createElement('div');
    messageDiv.id = messageId;
    messageDiv.className = 'chat-message loading-message';
    messageDiv.innerHTML = `
      <div id="${messageId}-text"><span class="thinking-icon">✨</span> <span class="thinking-text">Thinking about your question...</span></div>
      <div id="${messageId}-status" style="font-size: 10px; opacity: 0.8; margin-top: 4px;">Starting...</div>
    `;
    chatHistory.appendChild(messageDiv);
    scrollChatToBottom();
    
    // Add a progress indicator that updates
    let dots = 0;
    let elapsedSeconds = 0;
    
    const progressInterval = setInterval(() => {
      const textElement = document.getElementById(`${messageId}-text`);
      const statusElement = document.getElementById(`${messageId}-status`);
      
      if (textElement && statusElement) {
        dots = (dots + 1) % 4;
        elapsedSeconds++;
        
        const dotString = Array.from({length: dots}, (_, i) => 
          `<span class="thinking-dot" style="animation-delay: ${i * 0.15}s;">.</span>`
        ).join('');
        textElement.innerHTML = `<span class="thinking-icon">✨</span> <span class="thinking-text">Thinking about your question</span><span class="thinking-dots">${dotString}</span>`;
        
        // Update status based on elapsed time
        if (elapsedSeconds < 5) {
          statusElement.textContent = `Processing... (${elapsedSeconds}s)`;
        } else if (elapsedSeconds < 15) {
          statusElement.textContent = `AI is working on your answer... (${elapsedSeconds}s)`;
        } else if (elapsedSeconds < 30) {
          statusElement.textContent = `Complex question, still processing... (${elapsedSeconds}s)`;
        } else if (elapsedSeconds < 60) {
          statusElement.textContent = `Almost there, generating detailed response... (${elapsedSeconds}s)`;
        } else {
          statusElement.textContent = `Taking longer than usual, but still working... (${Math.floor(elapsedSeconds/60)}m ${elapsedSeconds%60}s)`;
        }
      } else {
        clearInterval(progressInterval);
      }
    }, 1000); // Update every second now
    
    // Store interval ID so we can clear it when removing the message
    messageDiv.dataset.progressInterval = progressInterval;
    
    return messageId;
  }

  function removeMessage(messageId) {
    const message = document.getElementById(messageId);
    if (message) {
      // Clear progress interval if it exists
      const intervalId = message.dataset.progressInterval;
      if (intervalId) {
        clearInterval(parseInt(intervalId));
      }
      message.remove();
    }
  }

  function addWelcomeMessage() {
    const messageDiv = document.createElement('div');
    messageDiv.className = 'chat-message assistant-message';
    messageDiv.innerHTML = `
      <div>👋 Hello! I'm your AI assistant. Ask me any question and I'll do my best to help you.</div>
      <div class="message-timestamp">${new Date().toLocaleTimeString()}</div>
    `;
    chatHistory.appendChild(messageDiv);
  }

  function scrollChatToBottom() {
    // Scroll the whole page to bottom instead of just chat container
    window.scrollTo(0, document.body.scrollHeight);
  }

  async function checkPendingChatText() {
    try {
      const result = await chrome.storage.local.get('pendingChatText');
      if (result.pendingChatText) {
        const { text, source, timestamp } = result.pendingChatText;
        
        // Only process if it's recent (within last 5 minutes)
        if (Date.now() - timestamp < 300000) {
          addTextFromContentScript(text, source);
        }
        
        // Clear the pending text
        await chrome.storage.local.remove('pendingChatText');
      }
    } catch (error) {
      console.error('Error checking pending chat text:', error);
    }
  }

  function addTextFromContentScript(text, source) {
    // Only add if we're authenticated and chat section is visible
    if (chatSection && chatSection.style.display !== 'none') {
      // Create a special message showing the selected text
      const messageDiv = document.createElement('div');
      messageDiv.className = 'chat-message user-message';
      
      const sourceUrl = new URL(source);
      const sourceDisplay = sourceUrl.hostname + sourceUrl.pathname;
      
      scrollChatToBottom();
      
      // Auto-populate the question input with a prompt
      if (questionInput) {
        const prompt = `Please analyze this selected text:\n\n"${text}"\n\nSource: ${source}`;
        questionInput.value = prompt;
        questionInput.focus();
      }
    }
  }

  function updateLoadingMessageStatus(messageId, status) {
    const statusElement = document.getElementById(`${messageId}-status`);
    if (statusElement && status) {
      let statusText = `Status: ${status}`;
      
      // Add helpful explanations for different statuses
      switch (status.toLowerCase()) {
        case 'pending':
          statusText = '⏳ Question received, queuing for processing...';
          break;
        case 'processing':
        case 'in_progress':
          statusText = '🔄 AI is analyzing your question...';
          break;
        case 'generating':
          statusText = '✍️ Generating your answer...';
          break;
        case 'generated':
          statusText = '✅ Answer generated!';
          break;
        case 'completed':
          statusText = '✅ Answer ready!';
          break;
        case 'failed':
        case 'error':
          statusText = '❌ Processing failed';
          break;
        default:
          statusText = `📊 Status: ${status}`;
      }
      
      statusElement.textContent = statusText;
    }
  }

  async function getAllDocuments() {
    await performAction('getDocuments', {}, 'Loading all documents...');
  }

  async function searchDocuments() {
    const query = searchInput.value.trim();
    if (!query) {
      actionError.textContent = 'Please enter a search query';
      return;
    }
    
    await performAction('searchDocuments', { query }, `Searching for "${query}"...`);
  }

  async function findSimilarDocuments() {
    const text = similarInput.value.trim();
    if (!text) {
      actionError.textContent = 'Please enter text to find similar documents';
      return;
    }
    
    await performAction('getSimilarDocuments', { text }, `Finding similar documents...`);
  }

  async function performAction(action, params, statusText) {
    clearActionMessages();
    actionStatus.textContent = statusText;
    
    // Disable all action buttons
    const actionButtons = [getAllDocsBtn, searchBtn, similarBtn];
    actionButtons.forEach(btn => btn.disabled = true);

    try {
      const result = await sendMessage({ action, ...params });
      
      if (result && result.success) {
        displayResults(result.data);
        actionStatus.textContent = 'Success!';
      } else {
        actionError.textContent = result?.error || 'Action failed';
        if (results) results.style.display = 'none';
      }
    } catch (error) {
      actionError.textContent = 'Error: ' + error.message;
      if (results) results.style.display = 'none';
    } finally {
      // Re-enable action buttons
      actionButtons.forEach(btn => btn.disabled = false);
    }
  }

  function displayResults(data) {
    if (!data) {
      if (results) {
        results.innerHTML = '<div>No data received</div>';
        results.style.display = 'block';
      }
      return;
    }

    // Handle paginated results (common in Rails apps)
    const documents = Array.isArray(data) ? data : (data.documents || []);
    
    if (documents.length === 0) {
      if (results) {
        results.innerHTML = '<div>No documents found</div>';
        results.style.display = 'block';
      }
      return;
    }

    const resultHTML = documents.map(doc => `
      <div class="document-item">
        <div class="document-title">${escapeHtml(doc.title || 'Untitled')}</div>
        <div class="document-meta">
          ID: ${doc.id} | 
          Library: ${escapeHtml(doc.library?.name || 'N/A')} |
          Updated: ${formatDate(doc.updated_at)}
        </div>
        ${doc.url ? `<div class="document-meta">URL: <a href="${escapeHtml(doc.url)}" target="_blank">${escapeHtml(doc.url)}</a></div>` : ''}
      </div>
    `).join('');

    if (results) {
      results.innerHTML = resultHTML;
      results.style.display = 'block';
    }
  }

  function showAuthenticatedState() {
    // Show header bar and hide login section
    if (headerBar) headerBar.style.display = 'flex';
    if (loginSection) loginSection.style.display = 'none';
    
    if (chatSection) chatSection.style.display = 'block';
    
    clearMessages();
    
    // Show welcome message if chat is empty
    if (chatHistory.children.length === 0) {
      addWelcomeMessage();
    }
  }

  function showUnauthenticatedState() {
    // Hide header bar and show login section
    if (headerBar) headerBar.style.display = 'none';
    if (loginSection) loginSection.style.display = 'block';
    
    if (chatSection) chatSection.style.display = 'none';
    if (authStatus) authStatus.textContent = 'Not authenticated';
  }

  function setButtonState(button, text, disabled) {
    button.textContent = text;
    button.disabled = disabled;
  }

  function clearMessages() {
    if (authError) authError.textContent = '';
    clearActionMessages();
  }

  function clearActionMessages() {
    if (actionError) actionError.textContent = '';
    if (actionStatus) actionStatus.textContent = '';
  }

  async function loadConfiguration() {
    try {
      const result = await sendMessage({ action: 'getConfiguration' });
      if (result && result.success) {
        baseUrlInput.value = result.data.baseUrl;
        configStatus.textContent = 'Configuration loaded';
        configStatus.style.color = '#666';
      }
    } catch (error) {
      configError.textContent = 'Failed to load configuration';
    }
  }

  async function saveConfiguration() {
    const baseUrl = baseUrlInput.value.trim();

    // Basic validation
    if (!baseUrl) {
      configError.textContent = 'Base URL is required';
      return;
    }

    // Clear previous messages
    configError.textContent = '';
    configStatus.textContent = 'Saving...';
    configStatus.style.color = '#666';
    saveConfigBtn.disabled = true;

    try {
      const result = await sendMessage({ 
        action: 'updateConfiguration',
        baseUrl: baseUrl
      });

      if (result && result.success) {
        configStatus.textContent = '✅ Settings saved successfully!';
        configStatus.style.color = '#28a745';
        
        // If user was authenticated, they should re-authenticate with new URL
        const validation = await sendMessage({ action: 'validateToken' });
        if (!validation || !validation.valid) {
          showUnauthenticatedState();
          authStatus.textContent = 'Please re-authenticate with new URL';
        }
      } else {
        configError.textContent = result?.error || 'Failed to save settings';
      }
    } catch (error) {
      configError.textContent = 'Error: ' + error.message;
    } finally {
      saveConfigBtn.disabled = false;
      // Clear success message after 3 seconds
      setTimeout(() => {
        if (configStatus.textContent.includes('✅')) {
          configStatus.textContent = '';
        }
      }, 3000);
    }
  }

  function sendMessage(message) {
    return new Promise((resolve) => {
      chrome.runtime.sendMessage(message, resolve);
    });
  }

  // Get current page context (URL and title)
  async function getCurrentPageContext() {
    try {
      // Query the active tab
      const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
      if (tabs && tabs.length > 0) {
        const activeTab = tabs[0];
        return {
          url: activeTab.url || 'Unknown URL',
          title: activeTab.title || 'Unknown Title'
        };
      }
    } catch (error) {
      console.warn('Could not get current page context:', error);
    }
    
    // Fallback
    return {
      url: 'Unknown URL',
      title: 'Unknown Title'
    };
  }

  function escapeHtml(unsafe) {
    if (!unsafe) return '';
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }

  function formatDate(dateString) {
    if (!dateString) return 'N/A';
    try {
      return new Date(dateString).toLocaleDateString();
    } catch (e) {
      return dateString;
    }
  }
});

// Auto-refresh authentication status every 30 seconds
setInterval(async () => {
  const validation = await new Promise((resolve) => {
    chrome.runtime.sendMessage({ action: 'validateToken' }, resolve);
  });
  
  if (validation && !validation.valid) {
    // Token expired, show login form
    const loginForm = document.getElementById('loginForm');
    const userInfo = document.getElementById('userInfo');
    const documentSection = document.getElementById('documentSection');
    const authStatus = document.getElementById('authStatus');
    
    if (loginForm) loginForm.style.display = 'block';
    if (userInfo) userInfo.style.display = 'none';
    if (documentSection) documentSection.style.display = 'none';
    if (authStatus) authStatus.textContent = 'Session expired - please re-authenticate';
    
    // Use current UI structure
    showUnauthenticatedState();
  }
}, 30000);

