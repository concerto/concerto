require "test_helper"

class RichTextTest < ActiveSupport::TestCase
  setup do
    @large_position = positions(:two_graphic)
    @small_position = positions(:two_ticker)
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

  test "should render in a small position with little text" do
    rich_text = RichText.new(text: "Some text")
    assert rich_text.should_render_in?(@small_position)
  end

  test "should render in a large position with enough text" do
    rich_text = RichText.new(text: "a" * 100)
    assert rich_text.should_render_in?(@large_position)
  end

  test "should not render in a large position with little text" do
    rich_text = RichText.new(text: "a" * 99)
    assert_not rich_text.should_render_in?(@large_position)
  end

  test "should not render if text is blank" do
    rich_text = RichText.new(text: "")
    assert_not rich_text.should_render_in?(@large_position)
  end

  test "should not render if text is nil" do
    rich_text = RichText.new(text: nil)
    assert_not rich_text.should_render_in?(@large_position)
  end

  test "should not render if text is only HTML tags and whitespace" do
    rich_text = RichText.new(text: " <strong> <em> </em> </strong> ")
    assert_not rich_text.should_render_in?(@large_position)
  end

  test "should correctly calculate text length after stripping HTML" do
    rich_text_short = RichText.new(text: "<strong>" + ("a" * 99) + "</strong>")
    rich_text_long = RichText.new(text: "<strong>" + ("a" * 100) + "</strong>")

    assert_not rich_text_short.should_render_in?(@large_position), "Should not render short text in large position"
    assert rich_text_long.should_render_in?(@large_position), "Should render long text in large position"
  end
end
