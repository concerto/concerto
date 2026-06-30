<script setup>
defineProps({
  content: { type: Object, required: true },
  boxStyle: { type: String, required: false, default: '' },
});
</script>

<template>
  <iframe
    :src="content.url"
    :style="boxStyle"
    class="iframe-content"
    sandbox="allow-scripts allow-same-origin allow-popups allow-forms"
    referrerpolicy="no-referrer"
    loading="lazy"
  />
</template>

<style scoped>
  .iframe-content {
    width: 100%;
    height: 100%;
    border: 0;
  }
</style>
