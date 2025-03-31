require "test_helper"

class VideoTest < ActiveSupport::TestCase
  setup do
    @youtube_video = videos(:video_youtube)
    @vimeo_video = videos(:video_vimeo) # Assuming a fixture for Vimeo videos exists
  end

  test "should render videos in appropriate fields" do
    assert @youtube_video.should_render_in?(positions(:two_graphic)), positions(:two_graphic).aspect_ratio
    assert_not @youtube_video.should_render_in?(positions(:two_ticker)), positions(:two_ticker).aspect_ratio

    assert @vimeo_video.should_render_in?(positions(:two_graphic)), positions(:two_graphic).aspect_ratio
    assert_not @vimeo_video.should_render_in?(positions(:two_ticker)), positions(:two_ticker).aspect_ratio
  end

  test "extracts video id from youtube url" do
    assert_equal "eT4OAYjzV-s", @youtube_video.video_id
  end

  test "extracts video id from vimeo url" do
    assert_equal "897211169", @vimeo_video.video_id # Replace with the actual Vimeo ID from the fixture
  end

  test "JSON output includes video_id and video_source" do
    youtube_json = @youtube_video.as_json
    assert_equal "eT4OAYjzV-s", youtube_json[:video_id]
    assert_equal "youtube", youtube_json[:video_source]

    vimeo_json = @vimeo_video.as_json
    assert_equal "897211169", vimeo_json[:video_id] # Replace with the actual Vimeo ID from the fixture
    assert_equal "vimeo", vimeo_json[:video_source]
  end
end
