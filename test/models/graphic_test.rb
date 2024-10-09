require "test_helper"

class GraphicTest < ActiveSupport::TestCase
  setup do
    @graphic = graphics(:one)
  end

  test "has analyzed metadata" do
    assert_equal 4080, @graphic.image.metadata[:width]
    assert_equal 3072, @graphic.image.metadata[:height]
  end

  test "should render images in appropriate fields" do
    assert @graphic.should_render_in?(positions(:two_graphic))

    assert_not @graphic.should_render_in?(positions(:two_ticker))
  end
end
