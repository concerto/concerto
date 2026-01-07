<script setup>
import { onMounted, onBeforeUnmount, ref, shallowRef } from 'vue'

import ConcertoGraphic, { preload as preloadGraphic } from './ConcertoGraphic.vue';
import ConcertoRichText from './ConcertoRichText.vue';
import ConcertoVideo from './ConcertoVideo.vue';
import ConcertoClock from './ConcertoClock.vue';
import { useConfigVersion } from '../composables/useConfigVersion.js';

// Content is shown for 10 seconds if it does not have it's own duration.
const defaultDuration = 10;

// Disable any timers used to advance content.
// This is helpful when debugging when you need to "freeze" the frontend.
const disableTimer = false;

// Show debug border only in development mode
const isDevelopment = import.meta.env.DEV;

// Retry configuration
const INITIAL_RETRY_DELAY_MS = 1000;
const MAX_RETRY_DELAY_MS = 10000;
const LONG_RETRY_DELAY_MS = 60000;

// Track config version to detect changes
const { check: checkConfigVersion } = useConfigVersion('Field');

const contentTypeMap = new Map([
  ["Graphic", ConcertoGraphic],
  ["RichText", ConcertoRichText],
  ["Video", ConcertoVideo],
  ["Clock", ConcertoClock]
]);

/**
 * Map of content types to their preload functions.
 * Components that support preloading should export a preload(content) function.
 * The preload function should return a Promise that resolves when preloading completes.
 */
const preloadFunctionMap = new Map([
  ["Graphic", preloadGraphic],
]);

const props = defineProps({
  /**
   * API endpoint which will load content for this field.
   *
   * This typically looks like /frontend/screens/:screen_id/fields/:field_id/content.json.
   */
  apiUrl: {type: String, required: true},

  /**
   * CSS style to be applied to the field.
   *
   * This is often used to set font family and color to align with the template.
   */
  fieldStyle: {type: String, required: false, default: ''},
});

const currentContent = shallowRef(null);
const currentContentConfig = ref({});

const contentQueue = [];
let nextContentTimer = null;
let loadContentRetryTimer = null;

async function loadContent(retryCount = 0) {
  const maxRetries = 3;
  const retryDelay = Math.min(INITIAL_RETRY_DELAY_MS * Math.pow(2, retryCount), MAX_RETRY_DELAY_MS);

  try {
    const resp = await fetch(props.apiUrl);

    if (!resp.ok) {
      throw new Error(`HTTP error! status: ${resp.status}`);
    }

    // Check for config version changes and reload if needed
    if (checkConfigVersion(resp)) {
      return; // Stop processing since page is reloading
    }

    const contents = await resp.json();
    contentQueue.push(...contents);

    if (contentQueue.length > 0) {
      showNextContent();
    }
  } catch (error) {
    console.error(`Failed to load content (attempt ${retryCount + 1}/${maxRetries + 1}):`, error);

    if (retryCount < maxRetries) {
      console.debug(`Retrying in ${retryDelay}ms...`);
      loadContentRetryTimer = setTimeout(() => loadContent(retryCount + 1), retryDelay);
    } else {
      console.error('Max retries reached. Content loading failed.');
      // Schedule another attempt after a longer delay
      loadContentRetryTimer = setTimeout(() => loadContent(0), LONG_RETRY_DELAY_MS);
    }
  }
}

/**
 * Preloads the next content in the queue if it supports preloading.
 * Only checks the immediate next item - if it doesn't support preloading,
 * we'll try again when the next content comes up.
 * This is non-blocking and failures don't affect content display.
 */
async function preloadNextContent() {
  if (contentQueue.length === 0) {
    // No content to preload
    return;
  }

  const nextContent = contentQueue[0]; // Peek at next item
  const preloadFunction = preloadFunctionMap.get(nextContent.type);

  if (!preloadFunction) {
    // This content type doesn't support preloading, skip it
    return;
  }

  console.debug(`Preloading next content (${nextContent.type}):`, nextContent.id);

  try {
    await preloadFunction(nextContent);
  } catch (error) {
    // Preload errors are logged by the preload function
    // We catch here to prevent unhandled promise rejections
    console.error('Unexpected error in preload:', error);
  }
}

function showNextContent() {
  clearTimeout(nextContentTimer);

  const nextContent = contentQueue.shift();
  if (nextContent) {
    const nextContentType = contentTypeMap.get(nextContent.type);
    if (!nextContentType) {
      console.error(`Unknown content type: ${nextContent.type}`);
      next();
      return;
    }
    currentContent.value = nextContentType;
    currentContentConfig.value = nextContent;

    // Preload next content (non-blocking)
    preloadNextContent();
  }

  const duration = (nextContent?.duration || defaultDuration) * 1000;
  if (!disableTimer) {
    nextContentTimer = setTimeout(next, duration);
  } else {
    console.debug(`Timer disabled, but would have waited ${duration}.`)
  }
}

function next() {
  if (contentQueue.length > 0) {
    showNextContent();
  } else {
    loadContent();
  }
}

// The content has requested control of the next content timer.
// This is useful for content that has a timer of its own, such as video.
function delegateTimerToContent() {
  console.debug('Delegating timer to content');
  clearTimeout(nextContentTimer);
  nextContentTimer = null;
}

// lifecycle hooks
onMounted(() => {
  loadContent();
})

onBeforeUnmount(() => {
  clearTimeout(nextContentTimer);
  nextContentTimer = null;
  clearTimeout(loadContentRetryTimer);
  loadContentRetryTimer = null;
})
</script>

<template>
  <div
    class="field"
    :class="{ 'dev-border': isDevelopment }"
    :style="fieldStyle"
  >
    <Transition>
      <component
        :is="currentContent"
        :key="currentContentConfig.id"
        :content="currentContentConfig"
        @click="next"
        @take-over-timer="delegateTimerToContent"
        @next="next"
      />
    </Transition>
  </div>
</template>

<style scoped>
  .field {
    position: absolute;
    box-sizing: border-box;
  }

  .dev-border {
    border: 1px dashed yellow;
  }

  .v-enter-active,
  .v-leave-active {
    transition: opacity 0.5s ease;
    position: absolute;
  }

  .v-enter-from,
  .v-leave-to {
    opacity: 0;
  }
</style>