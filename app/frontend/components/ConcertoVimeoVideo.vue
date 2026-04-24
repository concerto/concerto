<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue';
import { useVideoWatchdog } from '../composables/useVideoWatchdog.js';

const VIMEO_API_URL = 'https://player.vimeo.com/api/player.js';
const API_LOAD_TIMEOUT_MS = 30000; // 30 seconds

const props = defineProps({
  content: { type: Object, required: true },
  boxStyle: { type: String, required: false, default: '' },
});

const emit = defineEmits(['takeOverTimer', 'next']);
const { ping: watchdogPing, stop: watchdogStop } = useVideoWatchdog(emit);

const videoId = computed(() => {
  return props.content.video_id;
});

const videoUrl = computed(() => {
  return `https://player.vimeo.com/video/${videoId.value}?autoplay=1&muted=1&loop=0&api=1&background=1`;
});

const playerRef = ref(null);
let player = null;

const aspectRatio = ref(props.content.aspect_ratio);

const hasDuration = computed(() => {
  return props.content.duration && props.content.duration > 0;
});

function isVimeoAPILoaded() {
  /* global Vimeo */
  return (window.Vimeo && window.Vimeo.Player);
}

async function loadVimeoAPI() {
  return new Promise((resolve, reject) => {
    // Check if script is already in the DOM
    const existingScript = document.querySelector(`script[src="${VIMEO_API_URL}"]`);
    if (existingScript) {
      // Script exists but API might still be loading
      // Wait for it to be ready with timeout
      const maxAttempts = API_LOAD_TIMEOUT_MS / 100;
      let attempts = 0;
      const checkReady = setInterval(() => {
        if (isVimeoAPILoaded()) {
          clearInterval(checkReady);
          resolve();
        } else if (attempts++ >= maxAttempts) {
          clearInterval(checkReady);
          console.error('Timed out waiting for Vimeo API to load.');
          reject(new Error('Vimeo API load timeout'));
        }
      }, 100);
      return;
    }

    const script = document.createElement('script');
    script.src = VIMEO_API_URL;
    script.onload = () => {
      console.debug('Vimeo Iframe API loaded');
      resolve();
    };
    document.head.appendChild(script);
  });
}

onMounted(async () => {
  if (!isVimeoAPILoaded()) {
    await loadVimeoAPI();
  }

  player = new Vimeo.Player(playerRef.value);

  if (props.content.aspect_ratio_auto) {
    Promise.all([player.getVideoWidth(), player.getVideoHeight()])
      .then(([width, height]) => {
        if (width > 0 && height > 0) {
          aspectRatio.value = `${width}/${height}`;
        }
      })
      .catch((error) => {
        console.warn('Failed to read Vimeo video dimensions:', error);
      });
  }

  player.on('play', () => {
    console.debug('Vimeo video is playing');
    watchdogPing();
    if (!hasDuration.value) {
      emit('takeOverTimer', {});
    } else {
      console.debug('Vimeo video has a duration, not taking over timer');
    }
  });

  player.on('timeupdate', () => {
    watchdogPing();
  });

  player.on('pause', () => {
    console.debug('Vimeo video is paused');
  });

  player.on('ended', () => {
    console.debug('Vimeo video ended');
    watchdogStop();
    if (!hasDuration.value) {
      emit('next', {});
    }
  });
})

onBeforeUnmount(() => {
  if (player && typeof player.destroy === 'function') {
    player.destroy();
    player = null;
  }
});
</script>

<template>
  <div
    class="video-container"
    :style="boxStyle"
  >
    <iframe
      ref="playerRef"
      class="player"
      type="text/html"
      frameborder="0"
      allow="autoplay"
      :src="videoUrl"
      :style="{ aspectRatio: aspectRatio }"
    />
  </div>
</template>

<style scoped>
.video-container {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.player {
  max-width: 100%;
  max-height: 100%;
}
</style>
