import { mergeConfig, defineConfig } from 'vitest/config'
import viteConfig from './vite.config'

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: 'jsdom',
      include: ['../../test/frontend/**/*'],
      css: true,
    },
    resolve: {
      alias: {
        // Change how Vue is loaded in tests to make CSS <style scoped> work.
        // ref: https://github.com/vuejs/test-utils/issues/1931#issuecomment-1374933460
        vue: 'vue/dist/vue.esm-bundler.js',
        '@vue/runtime-dom': '@vue/runtime-dom/dist/runtime-dom.esm-bundler.js',
      },
    },
  })
)
