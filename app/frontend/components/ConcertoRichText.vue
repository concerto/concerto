<script setup>
import { onMounted, ref } from 'vue'

const props = defineProps({
  content: {type: Object, required: true}
});

// The main div which holds the text.
const el = ref();

async function resizeText() {
  let element = el.value;

  let displayHeight = element.scrollHeight;
  let fieldHeight = element.offsetHeight;
  let fontScale = 100;

  // This is a very ineffecient, but simple approach.
  while (displayHeight > fieldHeight && fontScale > 1) {
    el.value.style.fontSize = `${fontScale}%`;
    fontScale--;

    displayHeight = element.scrollHeight;
  }
}

// lifecycle hooks
onMounted(() => {
  resizeText();
})

</script>

<template>
  <div ref="el" class="richtext">
    <div
      v-if="props.content.render_as == 'plaintext'"
      class="plaintext"
    >
      {{ props.content.text }}
    </div>
    <!-- eslint-disable vue/no-v-html -->
    <div
      v-if="props.content.render_as == 'html'"
      class="html"
      v-html="props.content.text"
    />
    <!--eslint-enable-->
  </div>
</template>

<style scoped>
  .richtext {
    height: 100%;
    width: 100%;
    overflow: hidden;
    font-size: 100%; /* Initial font size. */
  }
</style>