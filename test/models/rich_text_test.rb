require "test_helper"

class RichTextTest < ActiveSupport::TestCase
  # The Blue Swoosh template from db/seeds.rb, the geometry the fit model was
  # calibrated against (issues #1829/#1906).
  MAIN = Position.new(left: 0.025, top: 0.026, right: 0.592, bottom: 0.796)
  TICKER = Position.new(left: 0.221, top: 0.885, right: 0.975, bottom: 0.985)
  SIDEBAR = Position.new(left: 0.68, top: 0.015, right: 0.98, bottom: 0.811)

  def plaintext(chars)
    RichText.new(text: "a" * chars, config: { render_as: "plaintext" })
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

  test "mid-length text lands in the sidebar, not main" do
    # The original #1829 report: 162 chars was rendering in Main where it
    # blows up to a huge font; the sidebar shows it near the target size.
    scores = { main: plaintext(162).fit_score(MAIN),
               ticker: plaintext(162).fit_score(TICKER),
               sidebar: plaintext(162).fit_score(SIDEBAR) }

    assert scores[:sidebar] > scores[:main], "sidebar should beat main for 162 chars"
    assert scores[:main] > scores[:ticker], "main should beat a 2-line-plus ticker"
  end

  test "short text lands in the ticker" do
    scores = { main: plaintext(16).fit_score(MAIN),
               ticker: plaintext(16).fit_score(TICKER),
               sidebar: plaintext(16).fit_score(SIDEBAR) }

    assert scores[:ticker] > scores[:sidebar]
    assert scores[:sidebar] > scores[:main]
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
    # real defect. 16 chars in Main renders enormous yet must outscore
    # unreadably small text.
    huge_font = plaintext(16).fit_score(MAIN)
    tiny_font = plaintext(1000).fit_score(TICKER)

    assert huge_font > 0.5, "oversized text should still score well"
    assert huge_font > 10 * tiny_font, "unreadably small text should score far worse"
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
