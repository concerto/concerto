<script setup>
import { onMounted, ref } from 'vue'

const props = defineProps({
  content: {type: Object, required: true}
});

// A container stretched to fill the entire field.
const container = ref();
// The main div which holds the text.
const child = ref();

async function resizeText() {
  let containerElement = container.value;
  let contentElement = child.value;

  let displayHeight = contentElement.scrollHeight;
  let fieldHeight = containerElement.offsetHeight;
  let fontScale = 100;

  console.debug(`Field height: ${fieldHeight}, Display height: ${displayHeight}`);

  // First expand the content to fill the height of the div.
  while (displayHeight < fieldHeight) {
    container.value.style.fontSize = `${fontScale}%`;
    fontScale++;

    displayHeight = contentElement.scrollHeight;
  }

  // Then shrink it to fit.
  // Shrinking works better using the container scrollHeight instead of the content.
  displayHeight = containerElement.scrollHeight;
  while (displayHeight > fieldHeight && fontScale > 1) {
    container.value.style.fontSize = `${fontScale}%`;
    fontScale--;

    displayHeight = containerElement.scrollHeight;
  }
}

// lifecycle hooks
onMounted(() => {
  resizeText();
})

</script>

<template>
  <div
    ref="container"
    class="richtext"
  >
    <div ref="child">
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