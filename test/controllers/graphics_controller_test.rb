require "test_helper"

class GraphicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @graphic = graphics(:graphic_one)
  end

  test "should get index" do
    get graphics_url
    assert_response :success
  end

  test "should get new" do
    get new_graphic_url
    assert_response :success
  end

  test "should create graphic" do
    assert_difference("Graphic.count") do
      post graphics_url, params: { graphic: { content_attributes: { name: @graphic.content.name, duration: @graphic.content.duration, start_time: @graphic.content.start_time, end_time: @graphic.content.end_time } } }
    end

    assert_redirected_to graphic_url(Graphic.last)
  end

  test "should show graphic" do
    get graphic_url(@graphic)
    assert_response :success
  end

  test "should get edit" do
    get edit_graphic_url(@graphic)
    assert_response :success
  end

  test "should update graphic" do
    patch graphic_url(@graphic), params: { graphic: { content_attributes: { id: @graphic.content.id, name: @graphic.content.name, duration: @graphic.content.duration, start_time: @graphic.content.start_time, end_time: @graphic.content.end_time } } }
    assert_redirected_to graphic_url(@graphic)
  end

  test "should destroy graphic" do
    assert_difference("Graphic.count", -1) do
      delete graphic_url(@graphic)
    end

    assert_redirected_to graphics_url
  end
end
