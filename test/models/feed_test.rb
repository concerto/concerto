require "test_helper"

class FeedTest < ActiveSupport::TestCase
  setup do
    @feed = feeds(:one)
  end

  test "regular feeds are active for upload" do
    assert @feed.active_for_upload?
  end
end
