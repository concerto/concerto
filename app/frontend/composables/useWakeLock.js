import { ref, onMounted, onBeforeUnmount } from 'vue'

/**
 * Composable for managing Screen Wake Lock API to prevent display from turning off.
 *
 * @returns {Object} Object with reactive state properties
 * @returns {Ref<boolean>} isActive - Whether wake lock is currently active
 * @returns {Ref<boolean>} isSupported - Whether browser supports Wake Lock API
 * @returns {Ref<string|null>} error - Error message if wake lock acquisition failed
 */
export function useWakeLock() {
  const isActive = ref(false)
  const isSupported = ref('wakeLock' in navigator)
  const error = ref(null)

  let wakeLock = null

  /**
   * Acquire a screen wake lock.
   * This prevents the screen from dimming or turning off.
   */
  async function acquireWakeLock() {
    // Reset error state
    error.value = null

    // Check if Wake Lock API is supported
    if (!isSupported.value) {
      console.warn('[Wake Lock] Screen Wake Lock API is not supported in this browser')
      return
    }

    // Check if page is visible (required for wake lock acquisition)
    if (document.visibilityState !== 'visible') {
      console.debug('[Wake Lock] Page is not visible, skipping wake lock acquisition')
      return
    }

    try {
      wakeLock = await navigator.wakeLock.request('screen')
      isActive.value = true
      console.log('[Wake Lock] Screen wake lock acquired successfully')

      // Listen for wake lock release events
      wakeLock.addEventListener('release', () => {
        isActive.value = false
        console.log('[Wake Lock] Screen wake lock released')
      })
    } catch (err) {
      error.value = err.message
      isActive.value = false
      console.warn('[Wake Lock] Failed to acquire screen wake lock:', err)
    }
  }

  /**
   * Release the wake lock if it's currently held.
   */
  async function releaseWakeLock() {
    if (wakeLock) {
      try {
        await wakeLock.release()
        console.log('[Wake Lock] Screen wake lock released manually')
      } catch (err) {
        console.warn('[Wake Lock] Error releasing wake lock:', err)
      }
      wakeLock = null
      isActive.value = false
    }
  }

  /**
   * Handle visibility change events.
   * When page becomes visible again, re-acquire the wake lock.
   * The browser automatically releases the lock when page is hidden.
   */
  function handleVisibilityChange() {
    if (document.visibilityState === 'visible') {
      console.debug('[Wake Lock] Page became visible, re-acquiring wake lock')
      acquireWakeLock()
    } else {
      console.debug('[Wake Lock] Page hidden, wake lock will be automatically released')
      isActive.value = false
    }
  }

  onMounted(() => {
    // Acquire initial wake lock
    acquireWakeLock()

    // Listen for visibility changes to re-acquire lock when page becomes visible
    document.addEventListener('visibilitychange', handleVisibilityChange)
  })

  onBeforeUnmount(() => {
    // Clean up: release wake lock and remove event listener
    releaseWakeLock()
    document.removeEventListener('visibilitychange', handleVisibilityChange)
  })

  return {
    isActive,
    isSupported,
    error
  }
}
