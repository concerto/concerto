<script setup>
import { onMounted, ref } from 'vue'

import ConcertoGraphic from './ConcertoGraphic.vue';

const contentTypeMap = new Map([
  ["Graphic", ConcertoGraphic],
]);

const props = defineProps({
  apiUrl: String
});

const currentContentType = ref(null);
const currentContentConfig = ref({});

const contentQueue = []; 

async function loadContent() {
  const resp = await fetch(props.apiUrl);
  const contents = await resp.json();
  contentQueue.push(...contents);

  if (contentQueue.length > 0 ){
    showNextContent();
  }
}

function showNextContent() {
  const nextContent = contentQueue.shift();
  currentContentType.value = contentTypeMap.get(nextContent.type);
  currentContentConfig.value = nextContent;
}

function next() {
  if (contentQueue.length > 0) {
    showNextContent();
  } else {
    loadContent();
  }
}


// lifecycle hooks
onMounted(() => {
  loadContent();
})
</script>

<template>
  <div class="field">
    <component @click="next" :is="ConcertoGraphic" :content="currentContentConfig"/>
  </div>
</template>

<style scoped>
  .field {
    position: absolute;
    border: 1px dashed yellow;
  }
</style>