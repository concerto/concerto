require "test_helper"

class FeedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @feed = feeds(:one)
    @system_admin = users(:system_admin)
  end

  test "should get index" do
    get feeds_url
    assert_response :success
  end

  test "should get new with system admin" do
    sign_in @system_admin
    get new_feed_url
    assert_response :success
  end

  test "should create feed with system admin" do
    sign_in @system_admin
    assert_difference("Feed.count") do
      post feeds_url, params: { feed: { description: @feed.description, name: @feed.name } }
    end

    assert_redirected_to feed_url(Feed.last)
  end

  test "should show feed" do
    get feed_url(@feed)
    assert_response :success
  end

  test "should get edit with system admin" do
    sign_in @system_admin
    get edit_feed_url(@feed)
    assert_response :success
  end

  test "should update feed with system admin" do
    sign_in @system_admin
    patch feed_url(@feed), params: { feed: { description: @feed.description, name: @feed.name } }
    assert_redirected_to feed_url(@feed)
  end

  test "should destroy feed with system admin" do
    sign_in @system_admin
    assert_difference("Feed.count", -1) do
      delete feed_url(@feed)
    end

    assert_redirected_to feeds_url
  end

  # Authorization tests
  test "should allow group admin to create feed" do
    sign_in users(:admin)  # admin is a group admin
    assert_difference("Feed.count") do
      post feeds_url, params: { feed: { description: "New feed", name: "Test Feed" } }
    end
    assert_redirected_to feed_url(Feed.last)
  end

  test "should not allow non-group-admin to create feed" do
    sign_in users(:non_member)  # not a group admin
    assert_no_difference("Feed.count") do
      post feeds_url, params: { feed: { description: "New feed", name: "Test Feed" } }
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow system admin to update feed" do
    sign_in @system_admin
    patch feed_url(@feed), params: { feed: { name: "Updated by system admin" } }
    assert_redirected_to feed_url(@feed)
    @feed.reload
    assert_equal "Updated by system admin", @feed.name
  end

  test "should not allow non-system-admin to update feed" do
    sign_in users(:admin)  # even group admin can't update (limitation until #511)
    patch feed_url(@feed), params: { feed: { name: "Unauthorized update" } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @feed.reload
    assert_not_equal "Unauthorized update", @feed.name
  end

  test "should allow system admin to destroy feed" do
    sign_in @system_admin
    assert_difference("Feed.count", -1) do
      delete feed_url(@feed)
    end
    assert_redirected_to feeds_url
  end

  test "should not allow non-system-admin to destroy feed" do
    sign_in users(:admin)  # even group admin can't destroy (limitation until #511)
    assert_no_difference("Feed.count") do
      delete feed_url(@feed)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
