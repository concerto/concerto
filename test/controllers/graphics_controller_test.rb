require "test_helper"

class GraphicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @graphic = graphics(:one)
    @user = users(:admin)
  end

  test "should show graphic when not logged in" do
    get graphic_url(@graphic)
    assert_response :success
  end

  test "should redirect new when not logged in" do
    get new_graphic_url
    assert_redirected_to new_user_session_url
  end

  test "should get new when logged in" do
    sign_in @user
    get new_graphic_url
    assert_response :success
  end

  test "should redirect create when not logged in" do
    assert_no_difference("Graphic.count") do
      post graphics_url, params: { graphic: {
        duration: @graphic.duration, end_time: @graphic.end_time,
        name: @graphic.name, start_time: @graphic.start_time,
        feed_ids: @graphic.feed_ids
      } }
    end
    assert_redirected_to new_user_session_url
  end

  test "should create graphic when logged in" do
    sign_in @user
    assert_difference("Graphic.count") do
      post graphics_url, params: { graphic: {
        duration: @graphic.duration, end_time: @graphic.end_time,
        name: @graphic.name, start_time: @graphic.start_time,
        feed_ids: @graphic.feed_ids
      } }
    end
    assert_redirected_to graphic_url(Graphic.last)
  end

  test "should redirect edit when not logged in" do
    get edit_graphic_url(@graphic)
    assert_redirected_to new_user_session_url
  end

  test "should get edit when logged in" do
    sign_in @user
    get edit_graphic_url(@graphic)
    assert_response :success
  end

  test "should redirect update when not logged in" do
    patch graphic_url(@graphic), params: { graphic: {
      duration: @graphic.duration, end_time: @graphic.end_time,
      name: @graphic.name, start_time: @graphic.start_time,
      feed_ids: @graphic.feed_ids
    } }

    assert_redirected_to new_user_session_url
  end

  test "should update graphic when logged in" do
    sign_in @user
    patch graphic_url(@graphic), params: { graphic: {
      duration: @graphic.duration, end_time: @graphic.end_time,
      name: @graphic.name, start_time: @graphic.start_time,
      feed_ids: @graphic.feed_ids
    } }
    assert_redirected_to graphic_url(@graphic)
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference("Graphic.count") do
      delete graphic_url(@graphic)
    end
    assert_redirected_to new_user_session_url
  end

  test "should destroy graphic when logged in" do
    sign_in @user
    assert_difference("Graphic.count", -1) do
      delete graphic_url(@graphic)
    end
    assert_redirected_to contents_url
  end

  # Authorization tests
  test "should not allow non-owner to edit graphic" do
    sign_in users(:non_member)
    get edit_graphic_url(@graphic), headers: { "Referer" => graphic_url(@graphic) }
    assert_redirected_to graphic_url(@graphic)
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow non-owner to update graphic" do
    sign_in users(:non_member)
    patch graphic_url(@graphic), params: { graphic: {
      name: "Unauthorized update"
    } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @graphic.reload
    assert_not_equal "Unauthorized update", @graphic.name
  end

  test "should not allow non-owner to destroy graphic" do
    sign_in users(:non_member)
    assert_no_difference("Graphic.count") do
      delete graphic_url(@graphic)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
