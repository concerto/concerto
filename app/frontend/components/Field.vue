<script setup>
import { onMounted } from 'vue'

const props = defineProps({
  apiUrl: String
});


// lifecycle hooks
onMounted(() => {

})
</script>

<template>
  <div class="field">I fetch content from {{props.apiUrl}}</div>
</template>

<style scoped>
  .field {
    position: absolute;
    border: 1px dashed yellow;
  }
</style>