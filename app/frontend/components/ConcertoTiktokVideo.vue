<script setup>
import { computed, onMounted, onBeforeUnmount, ref } from 'vue';

const props = defineProps({
  content: { type: Object, required: true }
});

const emit = defineEmits(['takeOverTimer', 'next']);

const videoId = computed(() => {
  return props.content.video_id;
});

const videoUrl = computed(() => {
  return `https://www.tiktok.com/player/v1/${videoId.value}?autoplay=1&muted=1&loop=0&controls=0`;
});

const playerRef = ref(null);

const hasDuration = computed(() => {
  return props.content.duration && props.content.duration > 0;
});

function handlePlayerMessage(event) {
  // Validate message origin for security
  if (event.origin !== 'https://www.tiktok.com') {
    return;
  }

  // Only process messages from TikTok player
  if (!event.data || !event.data['x-tiktok-player']) {
    return;
  }

  const { type, value } = event.data;

  switch (type) {
  case 'onStateChange':
    // State values: -1 (init), 0 (ended), 1 (playing), 2 (paused), 3 (buffering)
    switch (value) {
    case 1: // playing
      console.debug('TikTok video is playing');
      if (!hasDuration.value) {
        emit('takeOverTimer', {});
      } else {
        console.debug('TikTok video has a duration, not taking over timer');
      }
      break;
    case 2: // paused
      console.debug('TikTok video is paused');
      break;
    case 0: // ended
      console.debug('TikTok video ended');
      if (!hasDuration.value) {
        emit('next', {});
      }
      break;
    }
    break;
  case 'onPlayerReady':
    console.debug('TikTok player is ready');
    break;
  case 'onError':
    console.error('TikTok player error:', value);
    break;
  }
}

onMounted(() => {
  window.addEventListener('message', handlePlayerMessage);
});

onBeforeUnmount(() => {
  window.removeEventListener('message', handlePlayerMessage);
});
</script>

<template>
  <iframe
    ref="playerRef"
    class="player"
    type="text/html"
    frameborder="0"
    allow="autoplay; encrypted-media"
    :src="videoUrl"
  />
</template>

<style scoped>
.player {
  height: 100%;
  width: 100%;
}
</style>
