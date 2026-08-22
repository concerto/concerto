require "test_helper"

class RichTextTest < ActiveSupport::TestCase
  # The Blue Swoosh template from db/seeds.rb, the geometry the fit model was
  # calibrated against (issues #1829/#1906). Fractional coordinates only
  # describe a shape alongside the canvas they sit on, so these carry one:
  # an image-less Template reports the default 16:9, which Blue Swoosh is.
  CANVAS = Template.new
  MAIN = Position.new(left: 0.025, top: 0.026, right: 0.592, bottom: 0.796, template: CANVAS)
  TICKER = Position.new(left: 0.221, top: 0.885, right: 0.975, bottom: 0.985, template: CANVAS)
  SIDEBAR = Position.new(left: 0.68, top: 0.015, right: 0.98, bottom: 0.811, template: CANVAS)

  ITEMS = %w[Soup Salad Chili Wrap Ziti Bowl Fruit Tea Coffee Cocoa Bagel Toast].freeze

  def plaintext(chars)
    RichText.new(text: "a" * chars, config: { render_as: "plaintext" })
  end

  # An HTML list: content whose line structure the author supplied, rather
  # than a position imposing it by wrapping.
  def list(count)
    items = ITEMS.take(count).map { |item| "<li>#{item}</li>" }.join
    RichText.new(text: "<ul>#{items}</ul>", config: { render_as: "html" })
  end

  test "should have valid render_as values" do
    rich_text = rich_texts(:plain_richtext)
    assert rich_text.valid?, rich_text.errors.full_messages.to_sentence

    rich_text.render_as = "html"
    assert rich_text.valid?, rich_text.errors.full_messages.to_sentence

    rich_text.render_as = "invalid_value"
    assert_not rich_text.valid?, rich_text.errors.full_messages.to_sentence

    rich_text.render_as = [ "html", "foo" ]
    assert_not rich_text.valid?, rich_text.errors.full_messages.to_sentence
  end

  test "text content is renderable whenever there is text" do
    assert plaintext(10).renderable?
    assert RichText.new(text: "<a href='https://example.com'>x</a>", config: { render_as: "html" }).renderable?
  end

  test "blank text is not renderable" do
    assert_not RichText.new(text: "").renderable?
    assert_not RichText.new(text: nil).renderable?
    assert_not RichText.new(text: "   ").renderable?
  end

  test "fit_score is positive for any text in any position" do
    # fit_score only ranks positions; nothing is ever rejected outright, so a
    # poor fit still renders when it is the only option (issue #1829).
    [ 5, 45, 134, 162, 1500 ].each do |chars|
      [ MAIN, TICKER, SIDEBAR ].each do |position|
        assert plaintext(chars).fit_score(position).positive?,
          "#{chars} chars should score positive everywhere"
      end
    end
  end

  test "mid-length text lands in the ticker, which wraps it just once" do
    # The #1829 report was 162 chars rendering in Main, where it blows up to
    # a huge font. It reads best as two ticker lines: the Sidebar renders it
    # larger but has to break one authored line into nine.
    scores = { main: plaintext(162).fit_score(MAIN),
               ticker: plaintext(162).fit_score(TICKER),
               sidebar: plaintext(162).fit_score(SIDEBAR) }

    assert scores[:ticker] > scores[:main], "ticker should beat main for 162 chars"
    assert scores[:main] > scores[:sidebar], "a nine-line column is the worst of the three"
  end

  test "short text lands in the ticker" do
    scores = { main: plaintext(16).fit_score(MAIN),
               ticker: plaintext(16).fit_score(TICKER),
               sidebar: plaintext(16).fit_score(SIDEBAR) }

    assert scores[:ticker] > scores[:main]
    assert scores[:main] > scores[:sidebar]
  end

  test "a wall of text lands in main as its least-bad position" do
    scores = { main: plaintext(1500).fit_score(MAIN),
               ticker: plaintext(1500).fit_score(TICKER),
               sidebar: plaintext(1500).fit_score(SIDEBAR) }

    assert scores[:main] > scores[:sidebar]
    assert scores[:sidebar] > scores[:ticker]
  end

  test "ticker scores degrade as text wraps to more lines" do
    one_line = plaintext(45).fit_score(TICKER)
    two_lines = plaintext(134).fit_score(TICKER)   # bamnet: 1-2 lines read fine
    three_lines = plaintext(250).fit_score(TICKER) # 3+ lines are hard to read

    assert one_line > two_lines
    assert two_lines > three_lines
    assert two_lines > 3 * three_lines, "the readability floor sits between 2 and 3 lines"
  end

  test "oversized text is penalized only mildly" do
    # Too-big is fine ("WELCOME STUDENTS" may render huge); too-small is the
    # real defect. Measured on content whose authored lines survive intact,
    # so this scores the legibility band rather than forced wrapping.
    huge_font = list(4).fit_score(MAIN)
    tiny_font = plaintext(1000).fit_score(TICKER)

    assert huge_font > 0.5, "oversized text should still score well"
    assert huge_font > 100 * tiny_font, "unreadably small text should score far worse"
  end

  test "line breaks the author wrote cost nothing, ones a position forces do" do
    # Six authored lines render as six lines in Main with nothing forced. The
    # same characters as one continuous run have to be broken to fit, and
    # score far worse for it.
    authored = RichText.new(text: ([ "b" * 20 ] * 6).join("<br>"), config: { render_as: "html" })

    assert authored.fit_score(MAIN) > plaintext(120).fit_score(MAIN)
  end

  test "newlines in plaintext are not authored breaks" do
    # The player applies no white-space rule to rich text, so plaintext
    # newlines collapse to spaces: it is always one continuous run.
    multiline = RichText.new(text: "alpha\nbeta", config: { render_as: "plaintext" })

    assert_equal plaintext("alpha beta".length).fit_score(MAIN), multiline.fit_score(MAIN)
  end

  test "a box's shape follows the template canvas, not a 16:9 assumption" do
    # Fractional coordinates describe a shape only alongside the canvas. The
    # Blue Swoosh ticker is a wide strip on a landscape screen, but the same
    # box on a portrait-mounted 9:16 screen is a squat block that fits far
    # less text per line — so it must not score the same.
    portrait = Template.new
    portrait.define_singleton_method(:aspect_ratio) { 9.0 / 16 }
    rotated = Position.new(left: 0.221, top: 0.885, right: 0.975, bottom: 0.985, template: portrait)

    assert plaintext(162).fit_score(TICKER) > plaintext(162).fit_score(rotated),
      "a wide strip should beat the same fractional box on a portrait canvas"
  end

  test "a tall list of short authored lines prefers the sidebar" do
    # Twelve authored lines drop into the tall narrow Sidebar without a
    # single forced break — the shape that field exists for.
    menu = list(12)

    assert menu.fit_score(SIDEBAR) > menu.fit_score(MAIN)
    assert menu.fit_score(MAIN) > menu.fit_score(TICKER)
  end

  test "html content is measured by its visible text" do
    html = RichText.new(text: "<strong>#{'a' * 162}</strong>", config: { render_as: "html" })

    assert_equal plaintext(162).fit_score(SIDEBAR), html.fit_score(SIDEBAR)
  end

  test "html with no visible text falls back to the neutral base score" do
    # A bare link or embed strips to nothing; it can't be measured but must
    # still render somewhere (issue #1829).
    embed = RichText.new(text: "<a href='https://example.com'></a>", config: { render_as: "html" })

    [ MAIN, TICKER, SIDEBAR ].each do |position|
      assert_equal 1.0, embed.fit_score(position)
    end
  end
end
