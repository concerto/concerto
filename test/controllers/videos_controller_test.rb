require "test_helper"

class VideosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @video = videos(:video_youtube)
  end

  test "should get index" do
    get videos_url
    assert_response :success
  end

  test "should get new" do
    get new_video_url
    assert_response :success
  end

  test "should create video" do
    sign_in users(:admin)

    assert_difference("Video.count") do
      post videos_url, params: { video: { duration: @video.duration, end_time: @video.end_time, name: @video.name, start_time: @video.start_time, url: @video.url } }
    end

    assert_redirected_to video_url(Video.last)
  end

  test "should show video" do
    get video_url(@video)
    assert_response :success
  end

  test "should get edit" do
    get edit_video_url(@video)
    assert_response :success
  end

  test "should update video" do
    patch video_url(@video), params: { video: { duration: @video.duration, end_time: @video.end_time, name: @video.name, start_time: @video.start_time, url: @video.url } }
    assert_redirected_to video_url(@video)
  end

  test "should destroy video" do
    assert_difference("Video.count", -1) do
      delete video_url(@video)
    end

    assert_redirected_to videos_url
  end
end
