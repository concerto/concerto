<script setup>
import { onMounted, ref, shallowRef } from 'vue'

import ConcertoGraphic from './ConcertoGraphic.vue';
import ConcertoRichText from './ConcertoRichText.vue';

// Content is shown for 10 seconds if it does not have it's own duration.
const defaultDuration = 10;

// Disable any timers used to advance content.
// This is helpful when debugging when you need to "freeze" the frontend.
const disableTimer = false;

const contentTypeMap = new Map([
  ["Graphic", ConcertoGraphic],
  ["RichText", ConcertoRichText],
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
    currentContent.value = contentTypeMap.get(nextContent.type);
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


// lifecycle hooks
onMounted(() => {
  loadContent();
})
</script>

<template>
  <div
    class="field"
    :style="fieldStyle"
  >
    <Transition>
      <component
        :is="currentContent"
        :key="currentContentConfig.id"
        :content="currentContentConfig"
        @click="next"
      />
    </Transition>
  </div>
</template>

<style scoped>
  .field {
    position: absolute;
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