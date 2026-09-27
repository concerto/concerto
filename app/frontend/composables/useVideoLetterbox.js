import { onMounted, onBeforeUnmount, ref, watch } from 'vue'

// Frames to wait for the position to be laid out before giving up. The field
// is usually sized on the first frame; this only covers a slow first layout.
const MAX_LAYOUT_RETRIES = 10

/**
 * Sizes a video iframe to the largest box of its aspect ratio that fits its
 * container, on browsers without CSS container query units.
 *
 * Where container query units exist, the component's CSS does this on its own
 * and this composable leaves the frame alone. Elsewhere CSS cannot express
 * "the largest box of this shape that fits": aspect-ratio arrived in Chrome 88,
 * and Firefox 89-109 has it but resolves it to the iframe's 300x150 default
 * size (see #1925). Tizen 5.5 (Chrome 69) and older WebOS panels (Chrome 53-79)
 * have neither, so we measure the container and set the frame's size directly.
 *
 * Until a measurement succeeds, the frame keeps the component's CSS fallback of
 * filling the position, so the worst case is the embed's own black bars rather
 * than a 300x150 player. See #2005.
 *
 * @param {Function} aspectRatio Getter returning the video's ratio as "W/H"
 * @returns {Object} containerRef to bind to the container, frameStyle for the iframe
 */
export function useVideoLetterbox(aspectRatio) {
  const containerRef = ref(null)
  const frameStyle = ref({})
  let resizeObserver = null
  let retryFrame = null
  let retries = 0

  function supportsContainerUnits() {
    return !!(window.CSS && CSS.supports && CSS.supports('width', '1cqw'))
  }

  function parseRatio(value) {
    const [width, height] = String(value).split('/').map(Number)
    return width > 0 && height > 0 ? width / height : null
  }

  function measure() {
    const container = containerRef.value
    const ratio = parseRatio(aspectRatio())
    if (!container || !ratio) {
      frameStyle.value = {}
      return
    }

    const boxWidth = container.clientWidth
    const boxHeight = container.clientHeight
    if (boxWidth === 0 || boxHeight === 0) {
      // Not laid out yet; try again next frame rather than keep a bad size.
      if (retries < MAX_LAYOUT_RETRIES && window.requestAnimationFrame) {
        retries += 1
        retryFrame = window.requestAnimationFrame(measure)
      }
      return
    }

    retries = 0
    const width = Math.min(boxWidth, boxHeight * ratio)
    frameStyle.value = { width: `${width}px`, height: `${width / ratio}px` }
  }

  onMounted(() => {
    if (supportsContainerUnits()) return

    measure()

    // ResizeObserver arrived in Chrome 64; older panels fall back to the window.
    if (window.ResizeObserver) {
      resizeObserver = new ResizeObserver(() => measure())
      resizeObserver.observe(containerRef.value)
    } else {
      window.addEventListener('resize', measure)
    }
  })

  // Vimeo corrects its ratio after load, once the player reports its size.
  watch(aspectRatio, () => {
    if (!supportsContainerUnits()) measure()
  })

  onBeforeUnmount(() => {
    if (resizeObserver) resizeObserver.disconnect()
    window.removeEventListener('resize', measure)
    if (retryFrame !== null && window.cancelAnimationFrame) window.cancelAnimationFrame(retryFrame)
  })

  return {
    containerRef,
    frameStyle
  }
}
