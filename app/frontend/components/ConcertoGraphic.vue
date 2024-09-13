<script setup>
import { computed } from 'vue';

const props = defineProps({
  content: {type: Object, required: true}
});

const backgroundImageUrl = computed(() => {
  return `url(${props.content.image})`;
})

</script>

<template>
  <div class="graphic" />
</template>
  
<style scoped>
  .graphic {
    display: block;
    position: absolute;
    margin: auto;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-image: v-bind('backgroundImageUrl');
    background-size: contain;
    background-repeat: no-repeat;
    background-position: center;
  }
</style>