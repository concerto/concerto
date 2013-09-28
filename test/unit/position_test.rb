require 'test_helper'

class PositionTest < ActiveSupport::TestCase

  # Test the default values
  test "positions default to 0" do
    p = Position.new
    assert_equal 0, p.top
    assert_equal 0, p.left
    assert_equal 0, p.bottom
    assert_equal 0, p.right
    assert_equal 0, p.width
    assert_equal 0, p.height
  end
  
  # Test the height and width getters
  test "width reads correctly" do
    p = positions(:one)
    assert_equal 0, p.width-p.right+p.left
  end

  test "height reads correctly" do
    p = positions(:one)
    assert_equal 0, p.height-p.bottom+p.top
  end

  # Test the height and width setters
  test "width sets correctly" do
    p = Position.new(:left => 0.1)
    p.width = 0.5
    assert_equal 0.6, p.right
    assert_equal 0.5, p.width
    assert_equal 0.1, p.left
  end

  test "height sets correctly" do
    p = Position.new(:top => 0.1)
    p.height = 0.5
    assert_equal 0.6, p.bottom
    assert_equal 0.5, p.height
    assert_equal 0.1, p.top
  end

  #Hash import testing
  test "import basic hash" do
    p = Position.new({:template => templates(:one), :field => fields(:one)})
    h = {'top' => "0.1", 'left' => "0.2", 'bottom' => "0.3", 'right' => "0.4", 'style' => "style"}
    assert p.import_hash(h)
    assert_equal 0.1, p.top
    assert_equal 0.2, p.left
    assert_equal 0.3, p.bottom
    assert_equal 0.4, p.right
    assert_equal "style", p.style
    assert p.valid?
  end

  test "strip nasty styles" do
    p = positions(:one)
    p.style = 'color: #FFF !important; font-weight: boldest !important; foo: bar'
    p.save
    assert_equal 'color: #FFF ; font-weight: boldest ; foo: bar', p.style
  end
end
