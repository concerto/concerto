require "test_helper"

class VideoTest < ActiveSupport::TestCase
  setup do
    @video = videos(:video_youtube)
  end

  test "should render videos in appropriate fields" do
    assert @video.should_render_in?(positions(:two_graphic)), positions(:two_graphic).aspect_ratio

    assert_not @video.should_render_in?(positions(:two_ticker)), positions(:two_ticker).aspect_ratio
  end

  test "extracts video id from youtube url" do
    assert_equal "eT4OAYjzV-s", @video.video_id
  end
end
