<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'

defineProps({
  content: {type: Object, required: true},
  boxStyle: {type: String, required: false, default: ''},
});

const containerRef = ref(null)
const imgRef = ref(null)
let resizeObserver = null

// Constrain the binding axis to 100% and let the image's intrinsic
// aspect ratio drive the other dimension. The img element box ends up
// equal to the rendered content rectangle, so a boxStyle border hugs
// the image at any container size — including when the image has been
// scaled up to fill a position larger than its native pixel dimensions.
function fitImage() {
  const container = containerRef.value
  const img = imgRef.value
  if (!container || !img || !img.naturalWidth || !img.naturalHeight) return
  if (!container.clientWidth || !container.clientHeight) return

  const containerRatio = container.clientWidth / container.clientHeight
  const imageRatio = img.naturalWidth / img.naturalHeight

  if (imageRatio > containerRatio) {
    img.style.width = '100%'
    img.style.height = 'auto'
  } else {
    img.style.width = 'auto'
    img.style.height = '100%'
  }
}

onMounted(() => {
  if (window.ResizeObserver && containerRef.value) {
    resizeObserver = new ResizeObserver(fitImage)
    resizeObserver.observe(containerRef.value)
  }
})

onBeforeUnmount(() => {
  resizeObserver?.disconnect()
})
</script>

<template>
  <div
    ref="containerRef"
    class="graphic-container"
  >
    <img
      ref="imgRef"
      class="graphic"
      :src="content.image"
      :style="boxStyle"
      @load="fitImage"
    >
  </div>
</template>

<script>
/**
 * Preloads a graphic by creating an Image object and loading its source.
 * This allows the browser to cache the image before it's displayed.
 *
 * @param {Object} content - The content object containing the image URL
 * @returns {Promise} A promise that always resolves (never rejects) to avoid blocking content display
 */
export function preload(content) {
  return new Promise((resolve) => {
    const IMAGE_LOAD_TIMEOUT_MS = 30000; // 30 seconds

    if (!content || !content.image) {
      console.warn('ConcertoGraphic.preload: No image URL provided');
      resolve();
      return;
    }

    const img = new Image();
    let timeoutId = null;

    const cleanup = () => {
      if (timeoutId) {
        clearTimeout(timeoutId);
        timeoutId = null;
      }
      img.onload = null;
      img.onerror = null;
    };

    img.onload = () => {
      cleanup();
      resolve();
    };

    img.onerror = (error) => {
      console.warn(`Failed to preload graphic: ${content.image}`, error);
      cleanup();
      resolve(); // Resolve anyway, don't block display
    };

    timeoutId = setTimeout(() => {
      console.warn(`Timeout preloading graphic: ${content.image}`);
      cleanup();
      resolve(); // Resolve anyway, don't block display
    }, IMAGE_LOAD_TIMEOUT_MS);

    img.src = content.image;
  });
}
</script>

<style scoped>
  .graphic-container {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
  }

  .graphic {
    display: block;
    /* width and height are set in JS by fitImage() based on container
       and image aspect ratios so the element box matches the rendered
       content rectangle. */
  }
</style>
