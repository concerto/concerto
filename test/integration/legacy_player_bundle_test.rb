require "test_helper"

# Guards the @vitejs/plugin-legacy output that lets very old signage browsers
# (e.g. Chrome 53 on older LG WebOS screens, issue #1927) run the player.
#
# These read the built assets produced by `bin/rails vite:build` (run in CI
# before the test step, and auto-built by test_helper.rb in dev). They do NOT
# need a browser, so they run as part of `bin/rails test`.
class LegacyPlayerBundleTest < ActiveSupport::TestCase
  # Chrome 53 supports ES2015 syntax plus the ES2016 exponentiation operator,
  # but NOT async/await (Chrome 55), object spread (Chrome 60), optional
  # chaining or nullish coalescing (Chrome 80). Parsing every legacy chunk at
  # ecmaVersion 2016 proves plugin-legacy lowered everything Chrome 53 can't
  # parse, while still allowing the ES2015+ syntax it runs natively. We use a
  # real parser rather than a regex because a regex can't tell an async function
  # from a property named `async` (e.g. regenerator's `t.async = true`).
  ES2016_PARSE_JS = <<~JS.freeze
    const acorn = require('acorn'), fs = require('fs');
    for (const f of process.argv.slice(1)) {
      try { acorn.parse(fs.readFileSync(f, 'utf8'), { ecmaVersion: 2016 }); }
      catch (e) { console.error(f + ': ' + e.message); process.exit(1); }
    }
  JS

  setup do
    @manifest = JSON.parse(File.read(build_output_dir.join(".vite/manifest.json")))
  end

  test "manifest exposes both the modern and legacy player entrypoints" do
    assert @manifest.key?("entrypoints/player.js"),
      "modern player entrypoint missing from Vite manifest"
    assert @manifest.key?(legacy_player_key),
      "legacy player entrypoint missing -- is @vitejs/plugin-legacy configured?"
    assert polyfills_key,
      "legacy polyfills chunk missing from Vite manifest"
  end

  test "legacy player bundle is SystemJS format for browsers without ES modules" do
    # Chrome 53 cannot load <script type=module>; the legacy bundle must be
    # SystemJS (System.register) so it can load via the nomodule fallback.
    assert_includes legacy_player_source, "System.register",
      "legacy player bundle is not in SystemJS format"
  end

  test "modern player bundle still uses native ES modules" do
    modern = read_asset(@manifest.fetch("entrypoints/player.js")["file"])
    assert_match(/\bimport\b|\bexport\b/, modern,
      "modern player bundle no longer looks like an ES module")
  end

  test "every legacy chunk parses as ES2016 (no syntax Chrome 53 lacks)" do
    skip "node/acorn unavailable" unless node_with_acorn?

    legacy_chunks = Dir[build_output_dir.join("**/*-legacy-*.js")]
    assert legacy_chunks.any?, "no legacy chunks found in #{build_output_dir}"

    output = IO.popen([ "node", "-e", ES2016_PARSE_JS, *legacy_chunks ], err: [ :child, :out ], &:read)
    assert $?.success?,
      "a legacy chunk uses syntax Chrome 53 cannot parse:\n#{output}"
  end

  # plugin-legacy keeps the inline bootstrap snippets private (they are not
  # exported), so Frontend::PlayerHelper hardcodes copies. It DOES export
  # `cspHashes`: the base64 sha256 of exactly those snippets. Re-hashing our
  # copies against it turns a silent drift on a plugin-legacy upgrade -- which
  # would blank the Chrome 79 screens again (#1967) -- into a failing test.
  CSP_HASH_JS = <<~JS.freeze
    const crypto = require('crypto');
    import('@vitejs/plugin-legacy').then((m) => {
      const missing = process.argv.slice(1).filter(
        (s) => !m.cspHashes.includes(crypto.hash('sha256', s, 'base64'))
      );
      if (missing.length) {
        console.error('not found in cspHashes:\\n' + missing.join('\\n'));
        process.exit(1);
      }
    });
  JS

  test "hardcoded plugin-legacy snippets still match the installed plugin" do
    skip "node unavailable" unless node_available?

    snippets = [
      Frontend::PlayerHelper::SYSTEM_JS_INLINE_CODE,
      Frontend::PlayerHelper::DETECT_MODERN_BROWSER_CODE,
      Frontend::PlayerHelper::DYNAMIC_FALLBACK_INLINE_CODE
    ]

    output = IO.popen([ "node", "-e", CSP_HASH_JS, *snippets ], err: [ :child, :out ], &:read)
    assert $?.success?,
      "Frontend::PlayerHelper's copies have drifted from @vitejs/plugin-legacy.\n" \
      "Re-copy them from the plugin's dist/index.js.\n#{output}"
  end

  private

  def node_available?
    system("node", "-e", "0", out: File::NULL, err: File::NULL)
  end

  def node_with_acorn?
    system("node", "-e", "require('acorn')", out: File::NULL, err: File::NULL)
  end

  def build_output_dir
    ViteRuby.instance.config.build_output_dir
  end

  def read_asset(file)
    File.read(build_output_dir.join(file))
  end

  def legacy_player_key
    "entrypoints/player-legacy.js"
  end

  def legacy_player_source
    @legacy_player_source ||= read_asset(@manifest.fetch(legacy_player_key)["file"])
  end

  # plugin-legacy emits the polyfills chunk under a name that has varied across
  # versions (e.g. "../../vite/legacy-polyfills-legacy"); match on the suffix.
  def polyfills_key
    @manifest.keys.find { |key| key.include?("legacy-polyfills") }
  end
end
