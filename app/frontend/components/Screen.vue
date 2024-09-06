<script setup>
import { ref, onMounted } from 'vue'

const props = defineProps({
  apiUrl: String
});

async function loadConfig() {
  const resp = await fetch(props.apiUrl);
  const screen = await resp.json();
  document.getElementById("background").style.backgroundImage = `url(${screen.template.background_uri})`;
}

// reactive state
const count = ref(0);

// functions that mutate state and trigger updates
function increment() {
  count.value++
}

// lifecycle hooks
onMounted(() => {
  console.log(`The initial count is ${count.value}.`);
  loadConfig();
})
</script>

<template>
  <div class="screen">
    <div id="background"></div>
    <button @click="increment">Count is: {{ count }}</button>
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
    background-repeat: no-repeat;
    background-size: 100% 100%;
  }
</style>