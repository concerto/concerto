<script setup>
import { computed } from 'vue';
import ConcertoYoutubeVideo from './ConcertoYoutubeVideo.vue';
import ConcertoVimeoVideo from './ConcertoVimeoVideo.vue';
import ConcertoTiktokVideo from './ConcertoTiktokVideo.vue';

const props = defineProps({
  content: { type: Object, required: true }
});

const videoSource = computed(() => {
  return props.content.video_source;
});

</script>

<template>
  <ConcertoYoutubeVideo
    v-if="videoSource === 'youtube'"
    :content="content"
  />
  <ConcertoVimeoVideo
    v-else-if="videoSource === 'vimeo'"
    :content="content"
  />
  <ConcertoTiktokVideo
    v-else-if="videoSource === 'tiktok'"
    :content="content"
  />
  <div v-else>
    Unsupported video source
  </div>
</template>