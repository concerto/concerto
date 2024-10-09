require "test_helper"

class GraphicTest < ActiveSupport::TestCase
  setup do
    analyze_graphics

    @graphic = graphics(:one)
  end

  test "should render images in appropriate fields" do
    assert @graphic.should_render_in?(positions(:two_graphic))

    assert_not @graphic.should_render_in?(positions(:two_ticker))
  end
end
