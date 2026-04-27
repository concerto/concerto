import { onMounted, onBeforeUnmount, ref } from 'vue'

/**
 * Composable for automatically resizing text to fill available space.
 * Uses binary search to find the optimal font size that fits within the container.
 *
 * @returns {Object} Object containing containerRef and childRef to be bound to template elements
 */
export function useTextResize() {
  const containerRef = ref(null)
  const childRef = ref(null)
  let resizeObserver = null

  /**
   * Resize text using binary search to find optimal font size.
   * This reduces layout reflows from O(n) to O(log n).
   */
  function resizeText() {
    const containerElement = containerRef.value
    const childElement = childRef.value

    if (!containerElement || !childElement) {
      console.error('Cannot resize text: missing container or child element')
      return
    }

    const fieldHeight = containerElement.offsetHeight
    const fieldWidth = containerElement.offsetWidth
    const initialHeight = childElement.scrollHeight

    if (initialHeight === 0 || fieldHeight === 0 || fieldWidth === 0) {
      console.error('Cannot resize text: zero dimension detected.')
      return
    }

    if (import.meta.env.DEV) {
      console.debug(`Field: ${fieldWidth}x${fieldHeight}, Initial content height: ${initialHeight}`)
    }

    // Use binary search to find optimal font size
    const MIN_FONT_SIZE = 1
    const MAX_FONT_SIZE = 2000 // Maximum font size for large TV displays
    let minSize = MIN_FONT_SIZE
    let maxSize = MAX_FONT_SIZE
    let bestSize = MIN_FONT_SIZE

    // Binary search for the largest font size that fits both dimensions.
    // Width matters for non-wrapping content (e.g. clock with white-space: nowrap)
    // where horizontal overflow doesn't cause vertical overflow.
    while (minSize <= maxSize) {
      const midSize = Math.floor((minSize + maxSize) / 2)

      // Set the font size and measure once
      containerElement.style.fontSize = `${midSize}%`
      const currentHeight = containerElement.scrollHeight
      const currentWidth = containerElement.scrollWidth

      if (currentHeight <= fieldHeight && currentWidth <= fieldWidth) {
        // This size fits, try larger
        bestSize = midSize
        minSize = midSize + 1
      } else {
        // Too large, try smaller
        maxSize = midSize - 1
      }
    }

    // Apply the best size found
    containerElement.style.fontSize = `${bestSize}%`
  }

  onMounted(() => {
    // Initial resize
    resizeText()

    // Watch for container size changes (e.g., window resize, content changes)
    if (containerRef.value && window.ResizeObserver) {
      resizeObserver = new ResizeObserver(() => {
        resizeText()
      })
      resizeObserver.observe(containerRef.value)
    }
  })

  onBeforeUnmount(() => {
    if (resizeObserver) {
      resizeObserver.disconnect()
    }
  })

  return {
    containerRef,
    childRef,
    resizeText
  }
}
