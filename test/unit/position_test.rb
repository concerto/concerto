require 'test_helper'

class PositionTest < ActiveSupport::TestCase

  # Test the default values
  test "positions default to 0" do
    p = Position.new
    assert_equal p.top, 0
    assert_equal p.left, 0
    assert_equal p.bottom, 0
    assert_equal p.right, 0
    assert_equal p.width, 0
    assert_equal p.height, 0
  end
  
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
    assert_equal p.left, 0.1
  end

  test "height sets correctly" do
    p = Position.new(:top => 0.1)
    p.height = 0.5
    assert_equal p.bottom, 0.6
    assert_equal p.height, 0.5
    assert_equal p.top, 0.1
  end

  #Hash import testing
  test "import basic hash" do
    p = Position.new({:template => templates(:one), :field => fields(:one)})
    h = {'top' => "0.1", 'left' => "0.2", 'bottom' => "0.3", 'right' => "0.4", 'style' => "style"}
    assert p.import_hash(h)
    assert_equal p.top, 0.1
    assert_equal p.left, 0.2
    assert_equal p.bottom, 0.3
    assert_equal p.right, 0.4
    assert_equal p.style, "style"
    assert p.valid?
  end
end
