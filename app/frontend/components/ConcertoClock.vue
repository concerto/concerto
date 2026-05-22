<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
// TODO: Migrate from date-fns to the Temporal API (https://tc39.es/proposal-temporal/docs/)
// once it has broad browser support. Temporal provides native date/time formatting
// and manipulation without requiring a third-party library.
import { format as formatDate } from 'date-fns'
import { useTextResize } from '../composables/useTextResize'

// How frequently the clock updates.
const UPDATE_INTERVAL_MS = 1000;

// Locale codes are restricted to date-fns's naming convention (e.g. "nl", "en-US")
// to keep user input from reaching the dynamic import as an arbitrary path.
const LOCALE_CODE_PATTERN = /^[a-zA-Z]{2,3}(-[a-zA-Z]{2,4})?$/;

/**
 * MULTI-LINE FORMAT SUPPORT
 *
 * Supports multi-line displays using {br} delimiter. Format string is split on "{br}"
 * and each segment is formatted independently with date-fns.
 *
 * Examples:
 * - "M/d/yyyy{br}h:mm a" → displays date and time on separate lines
 * - "EEEE{br}M/d{br}h:mm a" → displays day, date, and time on three lines
 *
 * Notes:
 * - {br} is case-sensitive and whitespace around it is trimmed
 * - Empty segments render as blank lines
 * - {br} was chosen over \n or <br> for visibility in text inputs and safety (no v-html)
 */

/**
 * @typedef {object} ClockContent
 * @property {string} format - The date-fns format string for displaying the time.
 *                             Can include {br} tokens for multi-line display.
 * @property {string} [locale] - Optional date-fns locale code (e.g. "nl", "de", "fr").
 *                               When unset, date-fns defaults to en-US.
 */

const props = defineProps({
  /** @type {ClockContent} */
  content: {
    type: Object,
    required: true,
    validator: (value) => {
      if (typeof value.format !== 'string' || value.format.length === 0) return false;
      if (value.locale != null && typeof value.locale !== 'string') return false;
      return true;
    },
  },
});

// Store formatted time as array of lines (supports multi-line via {br} delimiter)
const currentTimeLines = ref([]);
let updateInterval = null;

// Lazy-loaded date-fns locale modules, code-split per locale by Vite at build
// time. Each entry is `() => import('date-fns/locale/<code>')`; the static
// prefix on the import path lets Vite generate the code-split chunks while
// the variable suffix is matched against the LOCALE_CODE_PATTERN above.
const LOCALE_LOADERS = import.meta.glob('../../../node_modules/date-fns/locale/*.js');

// Resolved date-fns Locale object, or null when unset or while loading.
// Falsy values cause formatDate to fall back to its en-US default.
let dateLocale = null;

// Use the text resize composable
const { containerRef, childRef, resizeText } = useTextResize()

/**
 * Dynamically loads a date-fns locale module. Returns the Locale object or null
 * if the code is invalid or the import fails.
 */
async function loadLocale(code) {
  if (!code) return null;
  if (!LOCALE_CODE_PATTERN.test(code)) {
    console.error(`ConcertoClock: invalid locale code "${code}" — using default.`);
    return null;
  }

  const loader = LOCALE_LOADERS[`../../../node_modules/date-fns/locale/${code}.js`];
  if (!loader) {
    console.error(`ConcertoClock: unknown locale "${code}" — using default.`);
    return null;
  }

  try {
    const mod = await loader();
    return mod.default ?? null;
  } catch (error) {
    console.error(`ConcertoClock: failed to load locale "${code}" — using default.`, error);
    return null;
  }
}

/**
 * Updates the displayed time by formatting the current date/time.
 *
 * If the format string contains {br} delimiters, it splits the format
 * and formats each segment independently, creating a multi-line display.
 */
async function updateTime() {
  try {
    const now = new Date();
    const options = dateLocale ? { locale: dateLocale } : undefined;

    // Split format string on {br} delimiter for multi-line support
    // Example: "M/d/yyyy{br}h:mm a" becomes ["M/d/yyyy", "h:mm a"]
    const formatSegments = props.content.format.split('{br}');

    // Format each segment separately using date-fns
    // Empty segments (from consecutive {br} or leading/trailing {br}) render as blank lines
    const newTimeLines = formatSegments.map(segment => {
      const trimmed = segment.trim();
      return trimmed ? formatDate(now, trimmed, options) : '';
    });

    // Compare arrays by joining to string (simple equality check)
    // Only update if the formatted time has actually changed
    const newTimeString = newTimeLines.join('|');
    const currentTimeString = currentTimeLines.value.join('|');

    if (newTimeString !== currentTimeString) {
      currentTimeLines.value = newTimeLines;

      // Wait for DOM update, then resize to fit the (potentially multi-line) content
      await nextTick();
      resizeText();
    }
  } catch (error) {
    console.error('Error formatting time:', error);
    // On error, show a single line with error message
    currentTimeLines.value = ['Invalid format'];
  }
}

onMounted(async () => {
  // Start ticking immediately so the clock displays even before the locale
  // module finishes loading. The first tick(s) may format in en-US; once the
  // locale resolves we re-render so users don't wait a full second.
  updateTime();
  updateInterval = setInterval(updateTime, UPDATE_INTERVAL_MS);

  if (props.content.locale) {
    dateLocale = await loadLocale(props.content.locale);
    if (dateLocale) {
      updateTime();
    }
  }
});

onBeforeUnmount(() => {
  if (updateInterval) {
    clearInterval(updateInterval);
  }
});
</script>

<template>
  <div
    ref="containerRef"
    class="concerto-clock"
  >
    <div
      ref="childRef"
      class="clock-display"
    >
      <!-- Render each line separately for multi-line support -->
      <!-- Single-line formats will have one line, multi-line will have multiple -->
      <div
        v-for="(line, index) in currentTimeLines"
        :key="index"
        class="clock-line"
      >
        {{ line }}
      </div>
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
  overflow: hidden;
  font-size: 100%; /* Initial font size */
}

.clock-display {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  font-weight: 600;
  text-align: center;
}

.clock-line {
  /* Each line in a multi-line clock */
  white-space: nowrap;
}
</style>
