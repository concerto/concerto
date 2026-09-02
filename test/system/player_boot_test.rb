require "application_system_test_case"

# Verifies the player boots in whatever browser the suite is pointed at, letting
# the browser itself choose between the modern and legacy bundles.
#
# This is the gap that let #1967 ship. Every other guard checks a bundle in
# isolation -- LegacyPlayerBundleTest parses the built chunks, LegacyPlayerTest
# hand-replays the SystemJS bootstrap, and the controller tests assert the tags
# are present -- so all of them stayed green while Chrome 61-104 silently picked
# the modern bundle and died. Only loading the real page in a real old browser
# catches that, which is what the legacy-browsers workflow does.
class PlayerBootTest < ApplicationSystemTestCase
  setup do
    @screen = screens(:e2e)
  end

  # Console errors the player emits today that are not failures. Anything not
  # listed here fails the test.
  IGNORED_CONSOLE_ERRORS = [
    # On a browser too old for the modern bundle, plugin-legacy throws twice on
    # purpose: once from the detector probe, once from the guard at the top of
    # the modern chunk. Its own fallback then logs "syntax error above and the
    # same error below should be ignored". Both carry this string.
    "import.meta.resolve not supported"
  ].freeze

  test "the player mounts and logs no unexpected console errors" do
    # Chrome's log buffer belongs to the browser process rather than the
    # Capybara session, so entries from earlier tests outlive reset_sessions!.
    # Drain it first, so we only judge this page load.
    severe_browser_logs

    visit frontend_player_url(@screen)

    # ConcertoScreen's static wrapper and background layer: present as soon as
    # Vue mounts, regardless of which content happens to be rotating.
    assert_selector "#screen .screen #background", wait: 20

    unexpected = severe_browser_logs.reject do |entry|
      IGNORED_CONSOLE_ERRORS.any? { |ignored| entry.message.include?(ignored) }
    end

    assert_empty unexpected.map(&:message),
      "player logged unexpected console errors; bundles loaded: #{loaded_player_bundles.inspect}"
  end

  private
    # The player scripts the browser actually fetched, by Resource Timing. Used
    # to say which bundle was chosen when the assertion above fails.
    def loaded_player_bundles
      page.evaluate_script(<<~JS)
        performance.getEntriesByType('resource')
          .map(function (e) { return e.name.replace(/^.*\\//, ''); })
          .filter(function (n) { return /^player.*\\.js/.test(n); })
      JS
    rescue StandardError
      []
    end
end
