<script setup>
import { computed } from 'vue';

const props = defineProps({
  content: {type: Object, required: true}
});

const videoUrl = computed(() => {
  return `http://www.youtube-nocookie.com/embed/${props.content.video_id}?rel=0&iv_load_policy=3&autoplay=1&controls=0&playsinline=1&mute=1`;
})

</script>

<template>
  <iframe
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