require "test_helper"

class ContentsHelperTest < ActionView::TestCase
  test "schedule_summary" do
    content = Content.new
    assert_equal "Always active", schedule_summary(content)

    content.start_time = "2001-02-03 00:00:00"
    assert_equal "Shown after 2001-02-03 00:00:00 UTC", schedule_summary(content)

    content.end_time = "2001-03-04 00:00:00"
    assert_equal "Shown between 2001-02-03 00:00:00 UTC and 2001-03-04 00:00:00 UTC", schedule_summary(content)

    content.start_time = nil
    assert_equal "Shown until 2001-03-04 00:00:00 UTC", schedule_summary(content)
  end
end
