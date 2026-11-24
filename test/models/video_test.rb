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
    assert @youtube_video.fit_score(positions(:two_graphic)).positive?, positions(:two_graphic).aspect_ratio
    assert_not @youtube_video.fit_score(positions(:two_ticker)).positive?, positions(:two_ticker).aspect_ratio

    assert @vimeo_video.fit_score(positions(:two_graphic)).positive?, positions(:two_graphic).aspect_ratio
    assert_not @vimeo_video.fit_score(positions(:two_ticker)).positive?, positions(:two_ticker).aspect_ratio

    assert @tiktok_video.fit_score(positions(:two_graphic)).positive?, positions(:two_graphic).aspect_ratio
    assert_not @tiktok_video.fit_score(positions(:two_ticker)).positive?, positions(:two_ticker).aspect_ratio
  end

  test "renders portrait videos in tall portrait positions" do
    assert @youtube_short.fit_score(positions(:two_sidebar)).positive?, positions(:two_sidebar).aspect_ratio
    assert @tiktok_video.fit_score(positions(:two_sidebar)).positive?, positions(:two_sidebar).aspect_ratio
  end

  test "rejects landscape videos in tall portrait positions" do
    # two_sidebar is only mildly portrait (~0.73) once corrected for the
    # template's real 16:9 canvas, and the video tolerance is loose (4x) by
    # design, so a 16:9 video actually fits there now. narrow_rail is a
    # genuinely narrow rail that a landscape video shouldn't fit.
    assert_not @youtube_video.fit_score(positions(:narrow_rail)).positive?, positions(:narrow_rail).aspect_ratio
    assert_not @vimeo_video.fit_score(positions(:narrow_rail)).positive?, positions(:narrow_rail).aspect_ratio
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

  test "audio defaults to false for legacy records with no audio key" do
    assert_not @youtube_video.audio?
    assert_not @youtube_video.as_json[:audio]
  end

  test "audio coerces string values to boolean" do
    @youtube_video.audio = "1"
    assert @youtube_video.audio?
    assert @youtube_video.as_json[:audio]

    @youtube_video.audio = "0"
    assert_not @youtube_video.audio?

    @youtube_video.audio = "true"
    assert @youtube_video.audio?

    @youtube_video.audio = nil
    assert_not @youtube_video.audio?
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

  test "requires a url" do
    @youtube_video.url = ""
    assert_not @youtube_video.valid?
    assert_includes @youtube_video.errors[:url], "can't be blank"
  end

  test "accepts valid http and https urls" do
    @youtube_video.url = "http://example.org/video"
    assert @youtube_video.valid?

    @youtube_video.url = "https://www.youtube.com/watch?v=eT4OAYjzV-s"
    assert @youtube_video.valid?
  end

  test "rejects non-http schemes" do
    @youtube_video.url = "javascript:alert(1)"
    assert_not @youtube_video.valid?
    assert_includes @youtube_video.errors[:url], "must be a valid http or https URL"
  end

  test "rejects urls without a host" do
    @youtube_video.url = "https://"
    assert_not @youtube_video.valid?
    assert_includes @youtube_video.errors[:url], "must be a valid http or https URL"
  end

  test "rejects malformed urls" do
    @youtube_video.url = "http://exa mple.com"
    assert_not @youtube_video.valid?
    assert_includes @youtube_video.errors[:url], "is not a valid URL"
  end

  test "video_source returns nil for malformed urls without raising" do
    @youtube_video.url = "http://exa mple.com"
    assert_nil @youtube_video.video_source
    assert_nil @youtube_video.video_id
  end

  test "caches Vimeo oEmbed responses in Rails.cache across instances" do
    memory_store = ActiveSupport::Cache::MemoryStore.new
    with_rails_cache(memory_store) do
      first = Video.find(@vimeo_video.id)
      second = Video.find(@vimeo_video.id)

      assert_equal "https://i.vimeocdn.com/video/1987724603-d_295x166", first.thumbnail_url
      assert_equal "https://i.vimeocdn.com/video/1987724603-d_295x166", second.thumbnail_url
      assert_requested :get, /vimeo\.com\/api\/oembed\.json/, times: 1
    end
  end

  test "caches TikTok oEmbed responses in Rails.cache across instances" do
    memory_store = ActiveSupport::Cache::MemoryStore.new
    with_rails_cache(memory_store) do
      first = Video.find(@tiktok_video.id)
      second = Video.find(@tiktok_video.id)

      assert_equal "6718335390845095173", first.video_id
      assert_equal "6718335390845095173", second.video_id
      assert_requested :get, /tiktok\.com\/oembed/, times: 1
    end
  end

  test "handles oEmbed timeouts gracefully and negatively caches errors briefly" do
    memory_store = ActiveSupport::Cache::MemoryStore.new
    stub_request(:get, /vimeo\.com\/api\/oembed\.json/).to_timeout

    with_rails_cache(memory_store) do
      assert_equal "", Video.find(@vimeo_video.id).thumbnail_url
      assert_equal "", Video.find(@vimeo_video.id).thumbnail_url
      assert_requested :get, /vimeo\.com\/api\/oembed\.json/, times: 1
    end
  end

  test "handles non-success oEmbed HTTP responses gracefully" do
    stub_request(:get, /vimeo\.com\/api\/oembed\.json/).to_return(status: 404, body: "Not Found")

    assert_equal "", @vimeo_video.thumbnail_url
  end

  test "caches resolved TikTok video_id in config on save so reads make no HTTP requests" do
    video = Video.create!(
      name: "Cached TikTok",
      url: "https://www.tiktok.com/@scout2015/video/6718335390845095173",
      user: users(:admin)
    )
    assert_equal "6718335390845095173", video.tiktok_video_id
    assert_requested :get, /tiktok\.com\/oembed/, times: 1

    # Freshly loaded record should not hit TikTok oEmbed again when rendering JSON.
    reloaded = Video.find(video.id)
    assert_equal "6718335390845095173", reloaded.as_json[:video_id]
    assert_requested :get, /tiktok\.com\/oembed/, times: 1

    # Updating a non-URL field does not re-fetch oEmbed.
    reloaded.update!(name: "Renamed TikTok")
    assert_requested :get, /tiktok\.com\/oembed/, times: 1

    # Changing URL to a different TikTok video updates tiktok_video_id.
    stub_request(:get, /tiktok\.com\/oembed/)
      .to_return(
        status: 200,
        body: { "html" => '<blockquote data-video-id="9999999999999999999"></blockquote>' }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    reloaded.update!(url: "https://vm.tiktok.com/ZM8newshort/")
    assert_equal "9999999999999999999", reloaded.reload.tiktok_video_id
    assert_equal "9999999999999999999", reloaded.video_id

    # Changing URL away from TikTok clears tiktok_video_id.
    reloaded.update!(url: "https://www.youtube.com/watch?v=eT4OAYjzV-s")
    assert_nil reloaded.reload.tiktok_video_id
    assert_equal "eT4OAYjzV-s", reloaded.video_id
  end

  private

  def with_rails_cache(store)
    original_cache = Rails.cache
    Rails.cache = store
    yield
  ensure
    Rails.cache = original_cache
  end
end
