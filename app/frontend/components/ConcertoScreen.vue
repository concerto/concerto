<script setup>
import { ref, onMounted, onBeforeUnmount, computed } from 'vue'
import ConcertoField from './ConcertoField.vue'

// Retry configuration
const INITIAL_RETRY_DELAY_MS = 1000;
const MAX_RETRY_DELAY_MS = 10000;
const LONG_RETRY_DELAY_MS = 60000;

const props = defineProps({
  apiUrl: {type: String, required: true}
});

const backgroundImage = ref("");
const positions = ref([]);
let loadConfigRetryTimer = null;

const backgroundImageStyle = computed(() => {
  return `url(${backgroundImage.value})`;
});

async function loadConfig(retryCount = 0) {
  const maxRetries = 3;
  const retryDelay = Math.min(INITIAL_RETRY_DELAY_MS * Math.pow(2, retryCount), MAX_RETRY_DELAY_MS);

  try {
    const resp = await fetch(props.apiUrl);

    if (!resp.ok) {
      throw new Error(`HTTP error! status: ${resp.status}`);
    }

    const screen = await resp.json();
    backgroundImage.value = screen.template.background_uri;
    positions.value = screen.positions;
  } catch (error) {
    console.error(`Failed to load screen configuration (attempt ${retryCount + 1}/${maxRetries + 1}):`, error);

    if (retryCount < maxRetries) {
      console.debug(`Retrying in ${retryDelay}ms...`);
      loadConfigRetryTimer = setTimeout(() => loadConfig(retryCount + 1), retryDelay);
    } else {
      console.error('Max retries reached. Screen configuration loading failed.');
      // Schedule another attempt after a longer delay
      loadConfigRetryTimer = setTimeout(() => loadConfig(0), LONG_RETRY_DELAY_MS);
    }
  }
}

// lifecycle hooks
onMounted(() => {
  loadConfig();
})

onBeforeUnmount(() => {
  clearTimeout(loadConfigRetryTimer);
  loadConfigRetryTimer = null;
})
</script>

<template>
  <div class="screen">
    <ConcertoField
      v-for="position in positions"
      :key="position.id"
      :api-url="position.content_uri"
      :field-style="position.style"
      :style="{
        top: (100 * position.top).toFixed(2) + '%',
        left: (100 * position.left).toFixed(2) + '%',
        height: (100 * (position.bottom-position.top)).toFixed(2) + '%',
        width: (100 * (position.right-position.left)).toFixed(2) + '%',
      }"
    />
    <div id="background" />
  </div>
</template>

<style scoped>
  .screen {
    height: 100%;
    width: 100%;
    overflow: hidden;
    /* cursor: none; */
  }

  #background {
    height: 100%;
    width: 100%;
    background-image: v-bind('backgroundImageStyle');
    background-repeat: no-repeat;
    background-size: 100% 100%;
  }
</style>