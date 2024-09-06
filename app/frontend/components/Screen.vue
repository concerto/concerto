<script setup>
import { ref, onMounted, computed } from 'vue'
import Field from './Field.vue'

const props = defineProps({
  apiUrl: String
});

const backgroundImage = ref("");
const positions = ref([]);

const backgroundImageStyle = computed(() => {
  return `url(${backgroundImage.value})`;
});

async function loadConfig() {
  const resp = await fetch(props.apiUrl);
  const screen = await resp.json();
  backgroundImage.value = screen.template.background_uri;

  screen.positions.forEach(position => {
    positions.value.push(position);
  });
}

// lifecycle hooks
onMounted(() => {
  loadConfig();
})
</script>

<template>
  <div class="screen">
    <Field v-for="position in positions"
      :api-url="position.content_uri"
      :style="{
        top: 100 * position.top + '%',
        left: 100 * position.left + '%',
        height: 100 * (position.bottom-position.top) + '%',
        width: 100 * (position.right-position.left) + '%',
      }"/>
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