<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue';

const VIMEO_API_URL = 'https://player.vimeo.com/api/player.js';
const API_LOAD_TIMEOUT_MS = 30000; // 30 seconds

const props = defineProps({
  content: { type: Object, required: true }
});

const emit = defineEmits(['takeOverTimer', 'next']);

const videoId = computed(() => {
  return props.content.video_id;
});

const videoUrl = computed(() => {
  return `https://player.vimeo.com/video/${videoId.value}?autoplay=1&muted=1&loop=0&api=1&background=1`;
});

const playerRef = ref(null);
let player = null;

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

  player.on('play', () => {
    console.debug('Vimeo video is playing');
    if (!hasDuration.value) {
      emit('takeOverTimer', {});
    } else {
      console.debug('Vimeo video has a duration, not taking over timer');
    }
  });

  player.on('pause', () => {
    console.debug('Vimeo video is paused');
  });

  player.on('ended', () => {
    console.debug('Vimeo video ended');
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
  <iframe
    ref="playerRef"
    class="player"
    type="text/html"
    frameborder="0"
    allow="autoplay"
    :src="videoUrl"
  />
</template>

<style scoped>
.player {
  height: 100%;
  width: 100%;
}
</style>
