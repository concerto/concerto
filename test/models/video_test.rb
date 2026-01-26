require "test_helper"

class VideoTest < ActiveSupport::TestCase
  setup do
    stub_oembed_apis
    @youtube_video = videos(:video_youtube)
    @youtube_short = videos(:video_youtube_short)
    @vimeo_video = videos(:video_vimeo)
    @tiktok_video = videos(:video_tiktok)
  end

  test "should render videos in appropriate fields" do
    assert @youtube_video.should_render_in?(positions(:two_graphic)), positions(:two_graphic).aspect_ratio
    assert_not @youtube_video.should_render_in?(positions(:two_ticker)), positions(:two_ticker).aspect_ratio

    assert @vimeo_video.should_render_in?(positions(:two_graphic)), positions(:two_graphic).aspect_ratio
    assert_not @vimeo_video.should_render_in?(positions(:two_ticker)), positions(:two_ticker).aspect_ratio

    assert @tiktok_video.should_render_in?(positions(:two_graphic)), positions(:two_graphic).aspect_ratio
    assert_not @tiktok_video.should_render_in?(positions(:two_ticker)), positions(:two_ticker).aspect_ratio
  end

  test "extracts video id from youtube url" do
    assert_equal "eT4OAYjzV-s", @youtube_video.video_id
  end

  test "extracts video id from youtube shorts url" do
    assert_equal "JnKnz3QaYhA", @youtube_short.video_id
  end

  test "youtube shorts have correct video source" do
    assert_equal "youtube", @youtube_short.video_source
  end

  test "extracts video id from vimeo url" do
    assert_equal "897211169", @vimeo_video.video_id
  end

  test "extracts video id from tiktok url" do
    assert_equal "6718335390845095173", @tiktok_video.video_id
  end

  test "JSON output includes video_id and video_source" do
    youtube_json = @youtube_video.as_json
    assert_equal "eT4OAYjzV-s", youtube_json[:video_id]
    assert_equal "youtube", youtube_json[:video_source]

    vimeo_json = @vimeo_video.as_json
    assert_equal "897211169", vimeo_json[:video_id]
    assert_equal "vimeo", vimeo_json[:video_source]

    tiktok_json = @tiktok_video.as_json
    assert_equal "6718335390845095173", tiktok_json[:video_id]
    assert_equal "tiktok", tiktok_json[:video_source]
  end
end
