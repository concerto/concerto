<script setup>
import { ref, onMounted, computed } from 'vue'

const props = defineProps({
  apiUrl: String
});

const backgroundImage = ref("");

const backgroundImageStyle = computed(() => {
  return `url(${backgroundImage.value})`;
});

async function loadConfig() {
  const resp = await fetch(props.apiUrl);
  const screen = await resp.json();
  backgroundImage.value = screen.template.background_uri;
}

// lifecycle hooks
onMounted(() => {
  loadConfig();
})
</script>

<template>
  <div class="screen">
    <div id="background"></div>
  </div>
</template>

<style scoped>
  .screen {
    height: 100%;
    width: 100%;
    overflow: hidden;
    /* cursor: none; */
  }

  #background {
    height: 100%;
    width: 100%;
    background-image: v-bind('backgroundImageStyle');
    background-repeat: no-repeat;
    background-size: 100% 100%;
  }
</style>