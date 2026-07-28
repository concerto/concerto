require "application_system_test_case"

# Verifies the @vitejs/plugin-legacy SystemJS bundle actually boots and mounts
# the Vue player, not just that it builds. Real Chrome 53 can't run in CI, so we
# drive the legacy bundle through modern headless Chrome: modern browsers ignore
# <script nomodule>, so we replay the same load sequence (SystemJS polyfills,
# then System.import of the legacy entry) by hand. This catches broken bundle
# wiring, a missing/renamed polyfills chunk, or SystemJS load errors -- the
# regressions most likely to surface on a future Vite/Vue upgrade.
class LegacyPlayerTest < ApplicationSystemTestCase
  setup do
    @screen = screens(:e2e)
  end

  test "SystemJS legacy bundle boots and mounts the player" do
    visit frontend_player_url(@screen)

    # Pull the fallback asset URLs straight from the rendered page so we exercise
    # exactly what an old browser's <script nomodule> tags would load. The
    # vite_plugin_legacy gem loads the polyfills via a src attribute but imports
    # the entry inline as System.import('...'), so each needs its own pattern.
    html = page.html
    polyfills_src = html[/nomodule[^>]*\bsrc="([^"]*polyfills-legacy[^"]*)"/, 1]
    entry_src = html[/System\.import\(['"]([^'"]*player-legacy[^'"]*)['"]\)/, 1]
    assert polyfills_src, "legacy polyfills <script nomodule> not found in page"
    assert entry_src, "legacy player System.import(...) not found in page"

    # Swap in a clean #screen (detaching the modern app), then load the SystemJS
    # polyfills and import the legacy entry -- the nomodule bootstrap sequence.
    page.execute_script(<<~JS, polyfills_src, entry_src)
      var polyfillsSrc = arguments[0], entrySrc = arguments[1];

      var old = document.getElementById('screen');
      var fresh = document.createElement('div');
      fresh.id = 'screen';
      fresh.setAttribute('data-api-url', old.getAttribute('data-api-url'));
      old.replaceWith(fresh);

      window.__legacyError = null;
      window.__legacyBooted = false;
      var poly = document.createElement('script');
      poly.src = polyfillsSrc;
      poly.onload = function () {
        window.System.import(entrySrc)
          .then(function () { window.__legacyBooted = true; })
          .catch(function (e) { window.__legacyError = String(e); });
      };
      poly.onerror = function () { window.__legacyError = 'failed to load polyfills'; };
      document.head.appendChild(poly);
    JS

    booted = page.evaluate_async_script(<<~JS)
      var done = arguments[0], start = Date.now();
      (function check() {
        if (window.__legacyError) return done('error: ' + window.__legacyError);
        if (window.__legacyBooted) return done('ok');
        if (Date.now() - start > 8000) return done('timeout');
        setTimeout(check, 100);
      })();
    JS
    assert_equal "ok", booted, "legacy SystemJS bundle did not import cleanly"

    # Once the legacy bundle boots, Vue mounts ConcertoScreen into #screen,
    # rendering its <div class="screen"> wrapper and #background layer. These are
    # static template elements (unlike the rotating content), so asserting on
    # them proves the bundle booted and mounted without depending on which piece
    # of content happens to be showing.
    assert_selector "#screen .screen #background", wait: 10
  end
end
