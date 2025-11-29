require "test_helper"

class VideosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @video = videos(:video_youtube)
    @user = users(:admin)
  end

  test "should show video when not logged in" do
    get video_url(@video)
    assert_response :success
  end

  test "should redirect new when not logged in" do
    get new_video_url
    assert_redirected_to new_user_session_url
  end

  test "should get new when logged in" do
    sign_in @user
    get new_video_url
    assert_response :success
  end

  test "should redirect create when not logged in" do
    assert_no_difference("Video.count") do
      post videos_url, params: { video: {
        duration: @video.duration, end_time: @video.end_time,
        name: @video.name, start_time: @video.start_time,
        url: @video.url
      } }
    end
    assert_redirected_to new_user_session_url
  end

  test "should create video when logged in" do
    sign_in @user
    assert_difference("Video.count") do
      post videos_url, params: { video: {
        duration: @video.duration, end_time: @video.end_time,
        name: @video.name, start_time: @video.start_time,
        url: @video.url
      } }
    end
    assert_redirected_to video_url(Video.last)
  end

  test "should redirect edit when not logged in" do
    get edit_video_url(@video)
    assert_redirected_to new_user_session_url
  end

  test "should get edit when logged in" do
    sign_in @user
    get edit_video_url(@video)
    assert_response :success
  end

  test "should redirect update when not logged in" do
    patch video_url(@video), params: { video: {
      duration: @video.duration, end_time: @video.end_time,
      name: @video.name, start_time: @video.start_time,
      url: @video.url
    } }
    assert_redirected_to new_user_session_url
  end

  test "should update video when logged in" do
    sign_in @user
    patch video_url(@video), params: { video: {
      duration: @video.duration, end_time: @video.end_time,
      name: @video.name, start_time: @video.start_time,
      url: @video.url
    } }
    assert_redirected_to video_url(@video)
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference("Video.count") do
      delete video_url(@video)
    end
    assert_redirected_to new_user_session_url
  end

  test "should destroy video when logged in" do
    sign_in @user
    assert_difference("Video.count", -1) do
      delete video_url(@video)
    end
    assert_redirected_to contents_url
  end

  # Authorization tests
  test "should not allow non-owner to edit video" do
    sign_in users(:non_member)
    get edit_video_url(@video), headers: { "Referer" => video_url(@video) }
    assert_redirected_to video_url(@video)
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow non-owner to update video" do
    sign_in users(:non_member)
    patch video_url(@video), params: { video: {
      name: "Unauthorized update"
    } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @video.reload
    assert_not_equal "Unauthorized update", @video.name
  end

  test "should not allow non-owner to destroy video" do
    sign_in users(:non_member)
    assert_no_difference("Video.count") do
      delete video_url(@video)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
