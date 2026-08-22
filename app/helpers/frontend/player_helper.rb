# Renders the @vitejs/plugin-legacy bootstrap for the player.
#
# The vite_plugin_legacy gem emits only the two <script nomodule> tags. A
# browser with ES modules skips those, so anything from Chrome 61 (modules) to
# 104 (no `import.meta.resolve`) loads the modern bundle and dies on the guard
# at the top of it -- the Chrome 79 WebOS screens in #1967. The detector and
# fallback below rescue them; the nomodule tags still cover Chrome 53 (#1927).
#
# The inline snippets are verbatim copies of private plugin-legacy code. Editing
# them fails LegacyPlayerBundleTest, which hashes them against `cspHashes`.
module Frontend::PlayerHelper
  # plugin-legacy's fallback looks the other two tags up by these ids.
  LEGACY_POLYFILL_ID = "vite-legacy-polyfill"
  LEGACY_ENTRY_ID = "vite-legacy-entry"

  # Reads the URL from the entry tag's data-src, so this stays a constant string.
  SYSTEM_JS_INLINE_CODE = "System.import(document.getElementById('vite-legacy-entry').getAttribute('data-src'))"

  # Throws on old browsers, leaving __vite_is_modern_browser unset. That error is
  # by design: it is the one from #1967, and only a bug if nothing catches it.
  DETECT_MODERN_BROWSER_CODE = "import'data:text/javascript,if(!import.meta.resolve)throw Error(\"import.meta.resolve not supported\")';import.meta.url;import(\"_\").catch(()=>1);(async function*(){})().next();window.__vite_is_modern_browser=true"

  # No flag set means load the SystemJS polyfills and the legacy entry by hand.
  DYNAMIC_FALLBACK_INLINE_CODE = "!function(){if(window.__vite_is_modern_browser)return;console.warn(\"vite: loading legacy chunks, syntax error above and the same error below should be ignored\");var e=document.getElementById(\"vite-legacy-polyfill\"),n=document.createElement(\"script\");n.src=e.src,n.onload=function(){System.import(document.getElementById('vite-legacy-entry').getAttribute('data-src'))},document.body.appendChild(n)}();"

  # Public: Replaces vite_legacy_javascript_tag with the complete tag set. The
  # detector must precede the fallback so the flag is set before it is read.
  # Skips safari10NoModuleFix -- Safari 10.1 is below our 13.1 floor.
  def vite_legacy_player_tags(name)
    return if ViteRuby.instance.dev_server_running?

    legacy_name = name.sub(/(\..+)|$/, '-legacy\1')

    safe_join [
      tag.script(nil, nomodule: true, crossorigin: true, id: LEGACY_POLYFILL_ID,
        src: vite_asset_path("legacy-polyfills", type: :virtual)),
      content_tag(:script, SYSTEM_JS_INLINE_CODE.html_safe, nomodule: true, crossorigin: true,
        id: LEGACY_ENTRY_ID, data: { src: vite_asset_path(legacy_name, type: :javascript) }),
      content_tag(:script, DETECT_MODERN_BROWSER_CODE.html_safe, type: "module"),
      content_tag(:script, DYNAMIC_FALLBACK_INLINE_CODE.html_safe, type: "module")
    ]
  end
end
