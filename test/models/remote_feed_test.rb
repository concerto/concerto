require "test_helper"

class RemoteFeedTest < ActiveSupport::TestCase
  setup do
    @feed = RemoteFeed.create!(
      name: "Test Remote Feed",
      url: "https://example.com/concerto/contents",
      group: groups(:system_administrators)
    )
    @sample_response = File.read(Rails.root.join("test/support/basic_remote_feed.json"))
  end

  test "refresh creates content from JSON response" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: @sample_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh

    assert_equal 3, @feed.content.count

    rich_texts = @feed.content.where(type: "RichText").order(:name)
    assert_equal 2, rich_texts.count

    html_content = rich_texts.find_by(name: "Welcome Message")
    assert_equal "<h1>Welcome</h1><p>Hello world!</p>", html_content.text
    assert_equal "html", html_content.render_as
    assert_equal 10, html_content.duration

    plain_content = rich_texts.find_by(name: "Plain Announcement")
    assert_equal "plaintext", plain_content.render_as

    video = @feed.content.find_by(type: "Video")
    assert_equal "Featured Video", video.name
    assert_equal "https://www.youtube.com/watch?v=dQw4w9WgXcQ", video.url
    assert_equal 30, video.duration
  end

  test "refresh creates graphic content with image attachment" do
    graphic_response = [
      {
        type: "Graphic",
        name: "Test Image",
        url: "https://example.com/image.png",
        duration: 15
      }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: graphic_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, "https://example.com/image.png")
      .to_return(status: 200, body: "fake-image-data", headers: { "Content-Type" => "image/png" })

    @feed.refresh

    graphic = @feed.content.find_by(type: "Graphic")
    assert_not_nil graphic
    assert_equal "Test Image", graphic.name
    assert_equal 15, graphic.duration
    assert graphic.image.attached?
  end

  test "refresh keeps unchanged items and removes deleted ones" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: @sample_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    @feed.reload
    assert_equal 3, @feed.content.count
    original_ids = @feed.content.pluck(:id).sort

    # Refresh again with the same data — should keep same records
    @feed.refresh
    @feed.reload
    assert_equal 3, @feed.content.count
    assert_equal original_ids, @feed.content.pluck(:id).sort

    # Refresh with fewer items — should remove the missing ones
    reduced_response = [
      {
        type: "RichText",
        name: "Welcome Message",
        text: "<h1>Welcome</h1><p>Hello world!</p>",
        render_as: "html",
        duration: 10
      }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: reduced_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    @feed.reload
    assert_equal 1, @feed.content.count
    assert_equal "Welcome Message", @feed.content.first.name
  end

  test "refresh updates last_refreshed" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    assert_nil @feed.last_refreshed
    @feed.refresh
    assert_not_nil @feed.last_refreshed
    assert_in_delta Time.now, @feed.last_refreshed, 2.seconds
  end

  test "refresh sets start_time and end_time from JSON" do
    start_time = "2025-06-01T00:00:00Z"
    end_time = "2025-12-31T23:59:59Z"
    response = [
      {
        type: "RichText",
        name: "Scheduled",
        text: "Scheduled content",
        render_as: "plaintext",
        start_time: start_time,
        end_time: end_time
      }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: response, headers: { "Content-Type" => "application/json" })

    @feed.refresh

    content = @feed.content.reload.first
    assert_not_nil content
    assert_equal Time.parse(start_time), content.start_time
    assert_equal Time.parse(end_time), content.end_time
  end

  test "refresh updates RichText content in place when data changes" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: @sample_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    original_id = @feed.content.find_by(name: "Welcome Message").id

    updated_response = [
      {
        type: "RichText",
        name: "Welcome Message",
        text: "<h1>Welcome</h1><p>Updated text!</p>",
        render_as: "html",
        duration: 15
      }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: updated_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    content = @feed.content.find_by(name: "Welcome Message")

    assert_equal original_id, content.id, "Content ID should be preserved on update"
    assert_equal "<h1>Welcome</h1><p>Updated text!</p>", content.text
    assert_equal 15, content.duration
  end

  test "refresh updates Video content in place when URL changes" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: @sample_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    original_id = @feed.content.find_by(name: "Featured Video").id

    updated_response = [
      {
        type: "Video",
        name: "Featured Video",
        url: "https://www.youtube.com/watch?v=newvideo",
        duration: 30
      }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: updated_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    content = @feed.content.find_by(name: "Featured Video")

    assert_equal original_id, content.id, "Content ID should be preserved on update"
    assert_equal "https://www.youtube.com/watch?v=newvideo", content.url
  end

  test "refresh updates Graphic content in place and re-downloads image when URL changes" do
    graphic_response = [
      { type: "Graphic", name: "Test Image", url: "https://example.com/image.png", duration: 15 }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: graphic_response, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://example.com/image.png")
      .to_return(status: 200, body: "original-image-data", headers: { "Content-Type" => "image/png" })

    @feed.refresh
    original_id = @feed.content.find_by(name: "Test Image").id

    updated_response = [
      { type: "Graphic", name: "Test Image", url: "https://example.com/new_image.png", duration: 15 }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: updated_response, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://example.com/new_image.png")
      .to_return(status: 200, body: "new-image-data", headers: { "Content-Type" => "image/png" })

    @feed.refresh
    content = @feed.content.find_by(name: "Test Image")

    assert_equal original_id, content.id, "Content ID should be preserved on update"
    assert content.image.attached?
  end

  test "refresh does not update content when data is unchanged" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: @sample_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    content = @feed.content.find_by(name: "Welcome Message")
    original_updated_at = content.updated_at

    @feed.refresh
    content.reload

    assert_equal original_updated_at, content.updated_at, "Content should not be touched when unchanged"
  end

  test "refresh creates new content when name changes" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: @sample_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    original_id = @feed.content.find_by(name: "Welcome Message").id

    renamed_response = [
      {
        type: "RichText",
        name: "New Name",
        text: "<h1>Welcome</h1><p>Hello world!</p>",
        render_as: "html",
        duration: 10
      }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: renamed_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh

    assert_nil @feed.content.find_by(id: original_id), "Old content should be removed when name changes"
    assert_not_nil @feed.content.find_by(name: "New Name")
  end

  test "refresh appends numbered suffix to duplicate name+type entries" do
    duplicate_response = [
      { type: "RichText", name: "Weather", text: "Sunny", render_as: "plaintext" },
      { type: "RichText", name: "Weather", text: "Rainy", render_as: "plaintext" }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: duplicate_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh

    assert_equal 2, @feed.content.count
    assert_not_nil @feed.content.find_by(name: "Weather (1)")
    assert_not_nil @feed.content.find_by(name: "Weather (2)")
    assert_equal "Sunny", @feed.content.find_by(name: "Weather (1)").text
    assert_equal "Rainy", @feed.content.find_by(name: "Weather (2)").text
  end

  test "refresh preserves IDs for consistently duplicate names across refreshes" do
    duplicate_response = [
      { type: "RichText", name: "Weather", text: "Sunny", render_as: "plaintext" },
      { type: "RichText", name: "Weather", text: "Rainy", render_as: "plaintext" }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: duplicate_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    original_ids = @feed.content.reload.pluck(:name, :id).to_h

    updated_response = [
      { type: "RichText", name: "Weather", text: "Cloudy", render_as: "plaintext" },
      { type: "RichText", name: "Weather", text: "Windy", render_as: "plaintext" }
    ].to_json

    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: updated_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh

    assert_equal original_ids["Weather (1)"], @feed.content.find_by(name: "Weather (1)").id
    assert_equal original_ids["Weather (2)"], @feed.content.find_by(name: "Weather (2)").id
    assert_equal "Cloudy", @feed.content.find_by(name: "Weather (1)").text
    assert_equal "Windy", @feed.content.find_by(name: "Weather (2)").text
  end

  test "refresh does not suffix unique names" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: @sample_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh

    assert_not_nil @feed.content.find_by(name: "Welcome Message")
    assert_nil @feed.content.find_by(name: "Welcome Message (1)")
  end

  test "destroys all associated content when remote feed is deleted" do
    stub_request(:get, "https://example.com/concerto/contents")
      .to_return(status: 200, body: @sample_response, headers: { "Content-Type" => "application/json" })

    @feed.refresh
    assert_equal 3, @feed.content.count
    content_ids = @feed.content.pluck(:id)

    @feed.destroy

    content_ids.each do |id|
      assert_nil Content.find_by(id: id), "Content #{id} should be destroyed after feed deletion"
    end
  end
end
