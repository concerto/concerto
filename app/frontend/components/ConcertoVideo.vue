<script setup>
import { computed } from 'vue';
import ConcertoYoutubeVideo from './ConcertoYoutubeVideo.vue';
import ConcertoVimeoVideo from './ConcertoVimeoVideo.vue';
import ConcertoTiktokVideo from './ConcertoTiktokVideo.vue';

const props = defineProps({
  content: { type: Object, required: true },
  boxStyle: { type: String, required: false, default: '' },
});

const videoSource = computed(() => {
  return props.content.video_source;
});

</script>

<template>
  <ConcertoYoutubeVideo
    v-if="videoSource === 'youtube'"
    :content="content"
    :box-style="boxStyle"
  />
  <ConcertoVimeoVideo
    v-else-if="videoSource === 'vimeo'"
    :content="content"
    :box-style="boxStyle"
  />
  <ConcertoTiktokVideo
    v-else-if="videoSource === 'tiktok'"
    :content="content"
    :box-style="boxStyle"
  />
  <div v-else>
    Unsupported video source
  </div>
</template>