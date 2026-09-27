require "application_system_test_case"

# Guards the geometry of video content on the player (#1925, #2005).
#
# An iframe has no natural size, so it only fills its position if the CSS pins
# down its dimensions; otherwise it renders at the 300x150 default object size.
# Two engine gaps have shipped that bug:
#
# - #1925: Gecko resolves aspect-ratio with only max-width/max-height to the
#   default size, where Blink transfers the constraint through the ratio. So
#   locally this runs in Firefox -- modern Chrome passes either way.
# - #2005: browsers without container query units (Tizen's Chrome 69, WebOS
#   Chrome 53-79) ignore the letterbox sizing entirely. The legacy-browsers
#   workflow runs this against Chrome 79 and Firefox 84 to cover that.
#
# Where container query units exist the video letterboxes to its own shape;
# elsewhere it fills the position and the embed letterboxes inside its frame.
#
# Everything here targets a main position, which is both where videos normally
# play and where a mis-sized player is most obvious.
class FrontendVideoLayoutTest < ApplicationSystemTestCase
  # A 1080p window: the fractional position coordinates only describe a real
  # shape on a 16:9 canvas, and at this size a mis-sized player is off by
  # hundreds of pixels rather than a handful. Locally that means Firefox (see
  # above); a remote grid only has the one browser it was started with.
  drive_with (REMOTE ? REMOTE_BROWSER : :firefox), screen_size: [ 1920, 1080 ]

  # Tolerance in CSS pixels. Sub-pixel layout rounding differs between engines,
  # and the failure this guards against is off by hundreds of pixels.
  LETTERBOX_TOLERANCE = 2.0

  setup do
    skip "Firefox is unavailable; #1925 only reproduces off Blink." unless browser_available?

    # A screen of our own, so the main position holds nothing but the video
    # under test and no other suite's fixtures rotate through it.
    @screen = Screen.create!(
      name: "Video layout test screen",
      template: templates(:two),
      group: groups(:screen_two_owners)
    )
    @feed = Feed.create!(
      name: "Frontend layout test feed",
      description: "Video feed used by the player layout system test",
      group: groups(:content_creators)
    )
    Subscription.create!(screen: @screen, field: fields(:main), feed: @feed)
  end

  test "landscape video fills the main position" do
    publish "https://www.youtube.com/watch?v=eT4OAYjzV-s"

    assert_fits_position ratio: 16.0 / 9.0
  end

  test "vertical video fills the main position" do
    publish "https://www.youtube.com/shorts/JnKnz3QaYhA"

    assert_fits_position ratio: 9.0 / 16.0
  end

  private
    # Locally we need Firefox, which is preinstalled on GitHub's runners. A
    # remote grid always has its own browser to run against: the
    # legacy-browsers workflow's Chrome 79 and Firefox 84 legs are the ones
    # that catch #2005.
    def browser_available?
      return true if REMOTE

      ENV["PATH"].to_s.split(File::PATH_SEPARATOR).any? do |dir|
        [ "firefox", "firefox-esr" ].any? { |binary| File.executable?(File.join(dir, binary)) }
      end
    end

    def publish(url)
      video = Video.create!(
        name: "Video for layout test",
        url: url,
        duration: 300,
        user: users(:admin)
      )
      Submission.create!(content: video, feed: @feed).moderate!(status: :approved, moderator: users(:admin))
    end

    # With container query units, the video should be the largest box of the
    # given ratio that fits inside its position: flush against one axis,
    # centered on the other. Without them, it should fill the position.
    def assert_fits_position(ratio:)
      visit frontend_player_url(@screen)
      assert_selector "iframe.player", count: 1, wait: 20

      metric = player_metric
      if metric["container_queries"]
        expected_width = [ metric["box_width"], metric["box_height"] * ratio ].min
        expected_height = expected_width / ratio
      else
        expected_width = metric["box_width"]
        expected_height = metric["box_height"]
      end

      message = "expected a #{ratio.round(2)} video to size to " \
                "#{expected_width.round}x#{expected_height.round} inside the " \
                "#{metric["box_width"].round}x#{metric["box_height"].round} main position, " \
                "got #{metric["width"].round}x#{metric["height"].round}"

      assert_in_delta expected_width, metric["width"], LETTERBOX_TOLERANCE, message
      assert_in_delta expected_height, metric["height"], LETTERBOX_TOLERANCE, message
    end

    # Measures the video iframe against the content box it is supposed to fill.
    def player_metric
      page.evaluate_script(<<~JS)
        (() => {
          const frame = document.querySelector('iframe.player');
          const box = frame.parentElement;
          const rect = frame.getBoundingClientRect();
          return {
            container_queries: !!(window.CSS && CSS.supports('width', '1cqw')),
            box_width: box.clientWidth,
            box_height: box.clientHeight,
            width: rect.width,
            height: rect.height
          };
        })();
      JS
    end
end
