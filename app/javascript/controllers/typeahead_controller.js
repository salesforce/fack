import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "hiddenField", "clearButton"]
  static values = { 
    url: String,
    minLength: { type: Number, default: 2 }
  }

  connect() {
    this.timeout = null
    this.selectedIndex = -1
    this.hideResults()
    this.updateClearButtonVisibility()
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  search() {
    const query = this.inputTarget.value.trim()
    
    // Update clear button visibility
    this.updateClearButtonVisibility()
    
    if (query.length < this.minLengthValue) {
      this.hideResults()
      this.clearSelection()
      return
    }

    // Clear existing timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce the search
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const users = await response.json()
        this.displayResults(users)
      }
    } catch (error) {
      console.error('Search failed:', error)
      this.hideResults()
    }
  }

  displayResults(users) {
    if (users.length === 0) {
      this.hideResults()
      return
    }

    this.resultsTarget.innerHTML = users.map((user, index) => 
      `<div class="typeahead-item px-3 py-2 cursor-pointer hover:bg-gray-100 border-b border-gray-200 last:border-b-0" 
           data-action="click->typeahead#selectUser" 
           data-user-id="${user.id}" 
           data-user-email="${user.email}"
           data-index="${index}">
         ${user.email}
       </div>`
    ).join('')
    
    this.showResults()
    this.selectedIndex = -1
  }

  selectUser(event) {
    const userId = event.currentTarget.dataset.userId
    const userEmail = event.currentTarget.dataset.userEmail
    
    this.inputTarget.value = userEmail
    this.hiddenFieldTarget.value = userId
    this.hideResults()
    this.selectedIndex = -1
    this.updateClearButtonVisibility()
  }

  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll('.typeahead-item')
    
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.updateSelection(items)
        break
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.updateSelection(items)
        break
      case 'Enter':
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        }
        break
      case 'Escape':
        this.hideResults()
        this.selectedIndex = -1
        break
    }
  }

  updateSelection(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-blue-100')
      } else {
        item.classList.remove('bg-blue-100')
      }
    })
  }

  showResults() {
    this.resultsTarget.classList.remove('hidden')
  }

  hideResults() {
    this.resultsTarget.classList.add('hidden')
  }

  clearSelection() {
    this.hiddenFieldTarget.value = ''
  }

  clear() {
    this.inputTarget.value = ''
    this.hiddenFieldTarget.value = ''
    this.hideResults()
    this.selectedIndex = -1
    this.updateClearButtonVisibility()
    this.inputTarget.focus()
  }

  updateClearButtonVisibility() {
    if (this.hasClearButtonTarget) {
      const hasValue = this.inputTarget.value.trim().length > 0
      if (hasValue) {
        this.clearButtonTarget.classList.remove('hidden')
      } else {
        this.clearButtonTarget.classList.add('hidden')
      }
    }
  }

  // Hide results when clicking outside
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // Connect the click outside listener
  inputTargetConnected() {
    document.addEventListener('click', this.handleClickOutside.bind(this))
  }

  // Disconnect the click outside listener
  inputTargetDisconnected() {
    document.removeEventListener('click', this.handleClickOutside.bind(this))
  }
}
