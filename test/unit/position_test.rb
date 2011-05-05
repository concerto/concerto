require 'test_helper'

class PositionTest < ActiveSupport::TestCase

  # Test the height and width getters
  test "width reads correctly" do
    p = positions(:one)
    assert_equal p.width-p.right+p.left, 0
  end

  test "height reads correctly" do
    p = positions(:one)
    assert_equal p.height-p.bottom+p.top, 0
  end

  # Test the height and width setters
  test "width sets correctly" do
    p = Position.new(:left => 0.1)
    p.width = 0.5
    assert_equal p.right, 0.6
    assert_equal p.width, 0.5
  end

  test "height sets correctly" do
    p = Position.new(:top => 0.1)
    p.height = 0.5
    assert_equal p.bottom, 0.6
    assert_equal p.height, 0.5
  end

end
