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

  test "effective_aspect_ratio defaults to 16/9 for regular YouTube videos" do
    assert_equal "16/9", @youtube_video.effective_aspect_ratio
  end

  test "effective_aspect_ratio defaults to 9/16 for YouTube shorts URLs" do
    assert_equal "9/16", @youtube_short.effective_aspect_ratio
  end

  test "effective_aspect_ratio defaults to 9/16 for TikTok" do
    assert_equal "9/16", @tiktok_video.effective_aspect_ratio
  end

  test "effective_aspect_ratio defaults to 16/9 for Vimeo" do
    assert_equal "16/9", @vimeo_video.effective_aspect_ratio
  end

  test "user-set aspect_ratio overrides provider default" do
    @youtube_video.aspect_ratio = "9:16"
    assert_equal "9/16", @youtube_video.effective_aspect_ratio
  end

  test "aspect_ratio of 'auto' falls back to provider default" do
    @youtube_video.aspect_ratio = "auto"
    assert_equal "16/9", @youtube_video.effective_aspect_ratio
    assert @youtube_video.as_json[:aspect_ratio_auto]
  end

  test "as_json exposes aspect_ratio and aspect_ratio_auto" do
    json = @youtube_video.as_json
    assert_equal "16/9", json[:aspect_ratio]
    assert json[:aspect_ratio_auto]

    @youtube_video.aspect_ratio = "1:1"
    json = @youtube_video.as_json
    assert_equal "1/1", json[:aspect_ratio]
    assert_not json[:aspect_ratio_auto]
  end

  test "aspect_ratio validation rejects unknown values" do
    @youtube_video.aspect_ratio = "21:9"
    assert_not @youtube_video.valid?
    assert_includes @youtube_video.errors[:aspect_ratio], "is not included in the list"
  end

  test "aspect_ratio validation accepts blank and listed values" do
    Video::ASPECT_RATIOS.each do |ratio|
      @youtube_video.aspect_ratio = ratio
      assert @youtube_video.valid?, "expected #{ratio.inspect} to be valid"
    end

    @youtube_video.aspect_ratio = nil
    assert @youtube_video.valid?

    @youtube_video.aspect_ratio = ""
    assert @youtube_video.valid?
  end
end
