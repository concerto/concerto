import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  build: {
    // Target older browsers more likely found on digital signage players.
    // This should be kept in-sync with player_controller.rb's allow_browser versions.
    target: ['chrome64', 'firefox69', 'safari13.1']
  },
  plugins: [
    RubyPlugin(),
    vue(),
  ],
})
