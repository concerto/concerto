<script setup>
import { useTextResize } from '../composables/useTextResize'

/**
 * @typedef {object} RichTextContent
 * @property {string} render_as - The format of the text, either 'plaintext' or 'html'.
 * @property {string} text - The actual text content to be rendered. May be plain text or HTML.
 */

const props = defineProps({
  /** @type {RichTextContent} */
  content: {
    type: Object,
    required: true,
    validator: (value) => {
      return ['plaintext', 'html'].includes(value.render_as) && typeof value.text === 'string';
    },
  },
});

// Use the text resize composable
const { containerRef: container, childRef: child } = useTextResize()

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