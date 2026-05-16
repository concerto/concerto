<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue';
import { useVideoWatchdog } from '../composables/useVideoWatchdog.js';

const YOUTUBE_API_URL = 'https://www.youtube.com/iframe_api';
const API_LOAD_TIMEOUT_MS = 30000; // 30 seconds
const TIME_CHECK_INTERVAL_MS = 5000;
// If the player hasn't reached PLAYING within this window when audio is on,
// assume the browser blocked autoplay-with-sound and fall back to muted.
const AUTOPLAY_FALLBACK_MS = 2000;

const props = defineProps({
  content: { type: Object, required: true },
  boxStyle: { type: String, required: false, default: '' },
});

const hasDuration = computed(() => {
  return props.content.duration && props.content.duration > 0;
});

const emit = defineEmits(['takeOverTimer', 'next'])
const { ping: watchdogPing, stop: watchdogStop } = useVideoWatchdog(emit);

const videoUrl = computed(() => {
  const params = [
    'rel=0',
    'iv_load_policy=3',
    'autoplay=1',
    'controls=0',
    'playsinline=1',
    'enablejsapi=1'
  ];
  if (!props.content.audio) {
    params.push('mute=1');
  }
  return `https://www.youtube-nocookie.com/embed/${props.content.video_id}?${params.join('&')}`;
})

const playerRef = ref(null);
let player = null;
let timeCheckInterval = null;
let lastKnownTime = -1;
let autoplayFallbackTimer = null;

function isYTAPILoaded() {
  /* global YT */
  return (window.YT && window.YT.Player);
}

async function loadYTAPI() {
  return new Promise((resolve, reject) => {
    // Check if script is already in the DOM
    const existingScript = document.querySelector(`script[src="${YOUTUBE_API_URL}"]`);
    if (existingScript) {
      // Script exists but API might still be loading
      // Wait for it to be ready with timeout
      const maxAttempts = API_LOAD_TIMEOUT_MS / 100;
      let attempts = 0;
      const checkReady = setInterval(() => {
        if (isYTAPILoaded()) {
          clearInterval(checkReady);
          resolve();
        } else if (attempts++ >= maxAttempts) {
          clearInterval(checkReady);
          console.error('Timed out waiting for YouTube API to load.');
          reject(new Error('YouTube API load timeout'));
        }
      }, 100);
      return;
    }

    window.onYouTubeIframeAPIReady = () => {
      console.debug('YouTube Iframe API loaded');
      resolve();
      // Clean up the global function after it's called
      delete window.onYouTubeIframeAPIReady;
    };

    const script = document.createElement('script');
    script.src = YOUTUBE_API_URL;
    document.head.appendChild(script);
  });
}

function startTimeCheck() {
  stopTimeCheck();
  timeCheckInterval = setInterval(() => {
    if (player && typeof player.getCurrentTime === 'function') {
      try {
        const currentTime = player.getCurrentTime();
        if (currentTime !== lastKnownTime) {
          lastKnownTime = currentTime;
          watchdogPing();
        }
      } catch {
        // Player may be destroyed or in error state
      }
    }
  }, TIME_CHECK_INTERVAL_MS);
}

function stopTimeCheck() {
  clearInterval(timeCheckInterval);
  timeCheckInterval = null;
}

function clearAutoplayFallback() {
  clearTimeout(autoplayFallbackTimer);
  autoplayFallbackTimer = null;
}

function fallbackToMuted() {
  if (!player || typeof player.mute !== 'function') return;
  console.warn('YouTube autoplay-with-sound blocked, falling back to muted');
  try {
    player.mute();
    player.playVideo();
  } catch (e) {
    console.error('Failed to fall back to muted playback:', e);
  }
}

function onPlayerError(event) {
  console.error('YouTube player error:', event.data);
  // Autoplay blocks manifest as the state never reaching PLAYING (handled
  // by the fallback timer). Other errors leave the player in a failed
  // state where re-issuing playVideo() wouldn't help, so cancel the
  // fallback rather than firing it pointlessly.
  clearAutoplayFallback();
}

function onPlayerStateChange(event) {
  switch (event.data) {
  case YT.PlayerState.PLAYING:
    console.debug('Video is playing');
    clearAutoplayFallback();
    watchdogPing();
    startTimeCheck();
    if (!hasDuration.value) {
      emit('takeOverTimer', {});
    } else {
      console.debug('Video has a duration, not taking over timer');
    }
    break;
  case YT.PlayerState.PAUSED:
    console.debug('Video is paused');
    stopTimeCheck();
    break;
  case YT.PlayerState.ENDED:
    console.debug('Video has ended');
    stopTimeCheck();
    watchdogStop();
    if (!hasDuration.value) {
      emit('next', {});
    }
    break;
  case YT.PlayerState.BUFFERING:
    // Reaching BUFFERING means the browser accepted the play request and
    // we're just waiting on the network — autoplay-with-sound wasn't
    // blocked, so cancel the muted fallback to avoid muting on slow loads.
    clearAutoplayFallback();
    break;
  default:
    console.debug('Video state changed:', event.data);
  }
}

onMounted(async () => {
  if (!isYTAPILoaded()) {
    await loadYTAPI();
  }

  player = new YT.Player(playerRef.value, {
    events: {
      'onStateChange': onPlayerStateChange,
      'onError': onPlayerError
    }
  });

  if (props.content.audio) {
    autoplayFallbackTimer = setTimeout(fallbackToMuted, AUTOPLAY_FALLBACK_MS);
  }
})

onBeforeUnmount(() => {
  clearAutoplayFallback();
  stopTimeCheck();
  if (player && typeof player.destroy === 'function') {
    player.destroy();
    player = null;
  }
})
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
      :style="{ aspectRatio: content.aspect_ratio }"
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
