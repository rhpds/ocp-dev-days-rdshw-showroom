;(function () {
  'use strict'

  const STORAGE_KEY = 'showroom-preferred-language'
  const DEFAULT_LANG = 'en'

  // Language configuration
  const languages = {
    en: { label: 'English', flag: '🇺🇸' },
    ja: { label: '日本語', flag: '🇯🇵' }
  }

  /**
   * Detect current language from URL path
   * @returns {string} Current language code ('en' or 'ja')
   */
  function detectCurrentLanguage() {
    const path = window.location.pathname

    if (path.includes('/modules/en/')) return 'en'
    if (path.includes('/modules/ja/')) return 'ja'

    // Fallback to stored preference or default
    return localStorage.getItem(STORAGE_KEY) || DEFAULT_LANG
  }

  /**
   * Switch to target language
   * @param {string} targetLang - Target language code
   */
  function switchLanguage(targetLang) {
    const currentPath = window.location.pathname
    const currentLang = detectCurrentLanguage()

    if (currentLang === targetLang) return

    // Store user preference
    localStorage.setItem(STORAGE_KEY, targetLang)

    // Replace language segment in path
    const newPath = currentPath.replace(`/modules/${currentLang}/`, `/modules/${targetLang}/`)

    // Navigate to translated page
    window.location.href = newPath
  }

  /**
   * Initialize language switcher dropdown
   */
  function initLanguageSwitcher() {
    const currentLang = detectCurrentLanguage()
    const switcher = document.querySelector('.language-switcher')

    if (!switcher) {
      console.warn('Language switcher container not found')
      return
    }

    // Create dropdown button
    const dropdownBtn = document.createElement('button')
    dropdownBtn.className = 'language-switcher-button'
    dropdownBtn.setAttribute('aria-haspopup', 'true')
    dropdownBtn.setAttribute('aria-expanded', 'false')

    const currentLangConfig = languages[currentLang]
    dropdownBtn.innerHTML = `${currentLangConfig.flag} ${currentLangConfig.label} <span class="dropdown-arrow">▼</span>`

    // Create dropdown menu
    const dropdown = document.createElement('div')
    dropdown.className = 'language-switcher-dropdown'
    dropdown.setAttribute('role', 'menu')
    dropdown.style.display = 'none'

    // Add language options
    Object.entries(languages).forEach(([code, config]) => {
      const option = document.createElement('button')
      option.className = 'language-switcher-option'
      option.setAttribute('role', 'menuitem')
      option.setAttribute('data-lang', code)
      option.innerHTML = `${config.flag} ${config.label}`

      if (code === currentLang) {
        option.classList.add('active')
        option.setAttribute('aria-current', 'true')
      }

      option.addEventListener('click', (e) => {
        e.stopPropagation()
        if (code !== currentLang) {
          switchLanguage(code)
        }
      })

      dropdown.appendChild(option)
    })

    // Toggle dropdown on button click
    dropdownBtn.addEventListener('click', (e) => {
      e.stopPropagation()
      const isOpen = dropdown.style.display === 'block'
      dropdown.style.display = isOpen ? 'none' : 'block'
      dropdownBtn.setAttribute('aria-expanded', !isOpen)
    })

    // Close dropdown when clicking outside
    document.addEventListener('click', () => {
      dropdown.style.display = 'none'
      dropdownBtn.setAttribute('aria-expanded', 'false')
    })

    switcher.appendChild(dropdownBtn)
    switcher.appendChild(dropdown)
  }

  // Initialize on page load
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initLanguageSwitcher)
  } else {
    initLanguageSwitcher()
  }
})()
