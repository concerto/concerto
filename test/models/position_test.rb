require "test_helper"

class PositionTest < ActiveSupport::TestCase
  setup do
    @position = positions(:two_graphic)
  end

  test "computes aspect ratio" do
    assert_equal @position.aspect_ratio.round(3), 0.736
  end
end
