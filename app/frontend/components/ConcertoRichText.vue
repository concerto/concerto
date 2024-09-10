<script setup>

const props = defineProps({
    content: {type: Object, required: true}
});

</script>

<template>
  <div>
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