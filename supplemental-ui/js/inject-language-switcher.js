;(function () {
  'use strict'

  /**
   * Inject language switcher into Showroom navbar
   */
  function injectLanguageSwitcher() {
    // Find the navbar-end div specifically
    const navbarEnd = document.querySelector('.navbar .navbar-end')

    if (!navbarEnd) {
      console.warn('Could not find .navbar .navbar-end to inject language switcher')
      return
    }

    // Check if already injected
    if (document.querySelector('.language-switcher')) {
      console.info('Language switcher already exists')
      return
    }

    // Create switcher container
    const switcher = document.createElement('div')
    switcher.className = 'language-switcher'
    switcher.setAttribute('role', 'navigation')
    switcher.setAttribute('aria-label', 'Language selection')

    // Insert inside navbar-end
    navbarEnd.appendChild(switcher)

    console.info('Language switcher container injected into navbar-end')
  }

  // Wait for DOM to be fully loaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', injectLanguageSwitcher)
  } else {
    // DOM already loaded, inject immediately
    injectLanguageSwitcher()
  }
})()
