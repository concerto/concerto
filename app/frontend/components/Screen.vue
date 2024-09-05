<script setup>
import { ref, onMounted } from 'vue'

const props = defineProps({
  screenId: Number
});

// reactive state
const count = ref(props.screenId)

// functions that mutate state and trigger updates
function increment() {
  count.value++
}

// lifecycle hooks
onMounted(() => {
  console.log(`The initial count is ${count.value}.`)
})
</script>

<template>
  <div class="screen">
    <button @click="increment">Count is: {{ count }}</button>
  </div>
</template>

<style scoped>
  .screen {
    height: 100%;
    width: 100%;
    overflow: hidden;
    cursor: none;
  }
</style>