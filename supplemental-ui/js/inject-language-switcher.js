;(function () {
  'use strict'

  /**
   * Inject language switcher into Showroom navbar
   */
  function injectLanguageSwitcher() {
    if (document.querySelector('.language-switcher')) return

    var toolbar = document.querySelector('div.toolbar')
    if (!toolbar) return

    var breadcrumbs = toolbar.querySelector('nav.breadcrumbs')

    var switcher = document.createElement('div')
    switcher.className = 'language-switcher'
    switcher.setAttribute('role', 'navigation')
    switcher.setAttribute('aria-label', 'Language selection')

    toolbar.insertBefore(switcher, breadcrumbs)
  }

  // Wait for DOM to be fully loaded
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', injectLanguageSwitcher)
  } else {
    // DOM already loaded, inject immediately
    injectLanguageSwitcher()
  }
})()
