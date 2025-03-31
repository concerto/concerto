<script setup>
import { computed, onMounted, ref } from 'vue';

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

const hasDuration = computed(() => {
  return props.content.duration && props.content.duration > 0;
});

function isVimeoAPILoaded() {
  /* global Vimeo */
  return (window.Vimeo && window.Vimeo.Player);
}

async function loadVimeoAPI() {
  return new Promise((resolve) => {
    const script = document.createElement('script');
    script.src = 'https://player.vimeo.com/api/player.js';
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

  const player = new Vimeo.Player(playerRef.value);

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
