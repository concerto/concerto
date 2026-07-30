require "test_helper"

class PositionTest < ActiveSupport::TestCase
  setup do
    @position = positions(:two_graphic)
  end

  test "computes aspect ratio" do
    # Corrected for the template's real 16:9 canvas (1920x1080, see
    # two_template_blob): the fractional box is 0.736 tall-looking, but on a
    # widescreen canvas it's actually wider than tall.
    assert_equal @position.aspect_ratio.round(3), 1.309
  end
end
