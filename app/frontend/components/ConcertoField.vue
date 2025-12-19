<script setup>
import { onMounted, ref, shallowRef } from 'vue'

import ConcertoGraphic from './ConcertoGraphic.vue';
import ConcertoRichText from './ConcertoRichText.vue';
import ConcertoVideo from './ConcertoVideo.vue';

// Content is shown for 10 seconds if it does not have it's own duration.
const defaultDuration = 10;

// Disable any timers used to advance content.
// This is helpful when debugging when you need to "freeze" the frontend.
const disableTimer = false;

// Show debug border only in development mode
const isDevelopment = import.meta.env.DEV;

const contentTypeMap = new Map([
  ["Graphic", ConcertoGraphic],
  ["RichText", ConcertoRichText],
  ["Video", ConcertoVideo]
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

async function loadContent() {
  const resp = await fetch(props.apiUrl);
  const contents = await resp.json();
  contentQueue.push(...contents);

  if (contentQueue.length > 0 ){
    showNextContent();
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