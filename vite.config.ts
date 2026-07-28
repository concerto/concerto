import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'
import legacy from '@vitejs/plugin-legacy'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    vue(),
    // Emit a second, SystemJS-based "legacy" bundle for signage browsers that
    // lack native ES modules (e.g. Chrome 53 on older LG WebOS screens, see
    // issue #1927). Modern browsers load the ESM bundle via <script type=module>
    // and never download the legacy chunks; old browsers fall back to the
    // legacy bundle via <script nomodule>. The Rails side is wired up with the
    // vite_plugin_legacy gem's vite_legacy_javascript_tag helper.
    legacy({
      // Legacy (SystemJS) target. Keep in-sync with player_controller.rb's
      // allow_browser chrome floor.
      targets: ['chrome >= 53'],
      // Modern (ESM) target. Keep in-sync with the other allow_browser floors.
      // Set explicitly because plugin-legacy's default modern floor is newer
      // than Safari 13.1, which we still support.
      modernTargets: ['chrome >= 64', 'firefox >= 69', 'safari >= 13.1'],
    }),
  ],
})
