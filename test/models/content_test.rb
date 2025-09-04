require "test_helper"

class ContentTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @admin = users(:admin)
  end

  test "active scope includes content that should be active" do
    # Content with no times (always active)
    assert_includes Content.active, graphics(:active_graphic_no_times)

    # Content with start in past, no end
    assert_includes Content.active, graphics(:active_graphic_with_start)

    # Content with no start, end in future
    assert_includes Content.active, rich_texts(:active_richtext_with_end)

    # Content with start in past, end in future
    assert_includes Content.active, rich_texts(:active_richtext_with_both)
  end

  test "active scope excludes content that should not be active" do
    # Expired content
    assert_not_includes Content.active, graphics(:expired_graphic)

    # Upcoming content
    assert_not_includes Content.active, graphics(:upcoming_graphic)
    assert_not_includes Content.active, rich_texts(:upcoming_richtext_no_end)
  end

  test "expired scope includes only content with end time in past" do
    assert_includes Content.expired, graphics(:expired_graphic)
  end

  test "expired scope excludes content without end time or with future end time" do
    # No end time
    assert_not_includes Content.expired, graphics(:active_graphic_no_times)
    assert_not_includes Content.expired, graphics(:active_graphic_with_start)

    # Future end time
    assert_not_includes Content.expired, rich_texts(:active_richtext_with_end)

    # Upcoming content
    assert_not_includes Content.expired, graphics(:upcoming_graphic)
  end

  test "upcoming scope includes only content with start time in future" do
    assert_includes Content.upcoming, graphics(:upcoming_graphic)
    assert_includes Content.upcoming, rich_texts(:upcoming_richtext_no_end)
  end

  test "upcoming scope excludes content without start time or with past start time" do
    # No start time
    assert_not_includes Content.upcoming, graphics(:active_graphic_no_times)
    assert_not_includes Content.upcoming, rich_texts(:active_richtext_with_end)

    # Past start time
    assert_not_includes Content.upcoming, graphics(:active_graphic_with_start)
    assert_not_includes Content.upcoming, rich_texts(:active_richtext_with_both)

    # Expired content
    assert_not_includes Content.upcoming, graphics(:expired_graphic)
  end

  test "scopes are mutually exclusive" do
    active_contents = Content.active.to_a
    expired_contents = Content.expired.to_a
    upcoming_contents = Content.upcoming.to_a

    assert_empty active_contents & expired_contents
    assert_empty active_contents & upcoming_contents
    assert_empty expired_contents & upcoming_contents
  end

  test "scopes work with time boundaries" do
    travel_to Time.current do
      # Active content (starts just before now)
      active_content = Graphic.create!(
        name: "Active Test", duration: 30, start_time: 1.second.ago,
        end_time: 1.hour.from_now, user: @admin
      )
      assert_includes Content.active, active_content

      # Expired content (ended just before now)
      expired_content = Video.create!(
        name: "Expired Test", duration: 30, start_time: 1.hour.ago,
        end_time: 1.second.ago, config: { 'url': "https://example.com" }, user: @admin
      )
      assert_includes Content.expired, expired_content

      # Upcoming content (starts just after now)
      upcoming_content = RichText.create!(
        name: "Upcoming Test", duration: 30, start_time: 1.second.from_now,
        end_time: 1.hour.from_now, text: "Test", config: { 'render_as': "plaintext" }, user: @admin
      )
      assert_includes Content.upcoming, upcoming_content
    end
  end

  test "scopes work across different content types" do
    # Verify scopes include multiple content types
    assert_includes Content.active.map(&:class).uniq, Graphic
    assert_includes Content.active.map(&:class).uniq, RichText

    assert_includes Content.expired.map(&:class).uniq, Graphic

    assert_includes Content.upcoming.map(&:class).uniq, Graphic
    assert_includes Content.upcoming.map(&:class).uniq, RichText
  end

  test "unused scope filters expired content with empty text and unused in name" do
    unused_content = RichText.create!(
      name: "Test Feed (unused)", duration: 30, text: "",
      start_time: 2.hours.ago, end_time: 1.hour.ago,
      config: { 'render_as': "plaintext" }, user: @admin
    )
    assert_includes Content.unused, unused_content
    assert_not_includes Content.used, unused_content
  end

  test "used scope includes active, upcoming, and non-unused expired content" do
    assert_includes Content.used, rich_texts(:active_richtext_with_end)
    assert_includes Content.used, rich_texts(:upcoming_richtext_no_end)

    expired_not_unused = RichText.create!(
      name: "Expired but not unused", duration: 30, text: "Some content",
      start_time: 2.hours.ago, end_time: 1.hour.ago,
      config: { 'render_as': "plaintext" }, user: @admin
    )
    assert_includes Content.used, expired_not_unused
  end
end
