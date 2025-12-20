<script setup>
import { computed } from 'vue';

const props = defineProps({
  content: {type: Object, required: true}
});

const backgroundImageUrl = computed(() => {
  return `url(${props.content.image})`;
})

</script>

<template>
  <div class="graphic" />
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
  .graphic {
    display: block;
    position: absolute;
    margin: auto;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-image: v-bind('backgroundImageUrl');
    background-size: contain;
    background-repeat: no-repeat;
    background-position: center;
  }
</style>
