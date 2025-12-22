<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
// TODO: Migrate from date-fns to the Temporal API (https://tc39.es/proposal-temporal/docs/)
// once it has broad browser support. Temporal provides native date/time formatting
// and manipulation without requiring a third-party library.
import { format as formatDate } from 'date-fns'

// How frequently the clock updates.
const UPDATE_INTERVAL_MS = 1000;

/**
 * @typedef {object} ClockContent
 * @property {string} format - The date-fns format string for displaying the time.
 */

const props = defineProps({
  /** @type {ClockContent} */
  content: {
    type: Object,
    required: true,
    validator: (value) => {
      return typeof value.format === 'string' && value.format.length > 0;
    },
  },
});

const currentTime = ref('');
let updateInterval = null;

function updateTime() {
  try {
    const now = new Date();
    currentTime.value = formatDate(now, props.content.format);
  } catch (error) {
    console.error('Error formatting time:', error);
    currentTime.value = 'Invalid format';
  }
}

onMounted(() => {
  // Update immediately on mount
  updateTime();

  // Then update every UPDATE_INTERVAL_MS
  updateInterval = setInterval(updateTime, UPDATE_INTERVAL_MS);
});

onBeforeUnmount(() => {
  if (updateInterval) {
    clearInterval(updateInterval);
  }
});
</script>

<template>
  <div class="concerto-clock">
    <div class="clock-display">
      {{ currentTime }}
    </div>
  </div>
</template>

<style scoped>
.concerto-clock {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
}

.clock-display {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-weight: 600;
  text-align: center;
  white-space: nowrap;
}
</style>
