ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Allow localhost connections for system tests, block all other external requests
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    include Devise::Test::IntegrationHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Each parallel tests has it's own folder.
    parallelize_setup do |i|
      ActiveStorage::Blob.service.root = "#{ActiveStorage::Blob.service.root}-#{i}"
    end

    # Clean up fixture attachments.
    parallelize_teardown do |i|
      FileUtils.rm_rf(ActiveStorage::Blob.services.fetch(:test_fixtures).root)
    end

    # Helper to stub oEmbed API requests (TikTok and Vimeo)
    # Call this in setup blocks of tests that use Video models with external URLs
    def stub_oembed_apis
      # TikTok oEmbed API - response based on actual API data
      stub_request(:get, /tiktok\.com\/oembed/)
        .to_return(
          status: 200,
          body: {
            "version" => "1.0",
            "type" => "video",
            "title" => "Scramble up ur name & I'll try to guess it",
            "author_url" => "https://www.tiktok.com/@scout2015",
            "author_name" => "Scout, Suki & Stella",
            "width" => "100%",
            "height" => "100%",
            "html" => '<blockquote class="tiktok-embed" cite="https://www.tiktok.com/@scout2015/video/6718335390845095173" data-video-id="6718335390845095173" data-embed-from="oembed" style="max-width:605px; min-width:325px;"></blockquote>',
            "thumbnail_url" => "https://p19-common-sign.tiktokcdn-us.com/example-thumbnail.jpg",
            "thumbnail_width" => 576,
            "thumbnail_height" => 1024,
            "provider_url" => "https://www.tiktok.com",
            "provider_name" => "TikTok",
            "author_unique_id" => "scout2015",
            "embed_product_id" => "6718335390845095173",
            "embed_type" => "video"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      # Vimeo oEmbed API - response based on actual API data
      stub_request(:get, /vimeo\.com\/api\/oembed\.json/)
        .to_return(
          status: 200,
          body: {
            "type" => "video",
            "version" => "1.0",
            "provider_name" => "Vimeo",
            "provider_url" => "https://vimeo.com/",
            "title" => "Staff Picks Best of the Year 2023",
            "author_name" => "Vimeo",
            "author_url" => "https://vimeo.com/staff",
            "is_plus" => "0",
            "account_type" => "enterprise",
            "html" => '<iframe src="https://player.vimeo.com/video/897211169"></iframe>',
            "width" => 426,
            "height" => 240,
            "duration" => 34,
            "description" => "",
            "thumbnail_url" => "https://i.vimeocdn.com/video/1987724603-d_295x166",
            "thumbnail_width" => 295,
            "thumbnail_height" => 166,
            "video_id" => 897211169,
            "uri" => "/videos/897211169"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    # Helper to stub RSS feed requests
    # Call this in setup blocks of tests that refresh RSS feeds
    def stub_rss_feeds
      stub_request(:get, /news\.yahoo\.com\/rss/)
        .to_return(
          status: 200,
          body: File.read(Rails.root.join("test/support/basic_rss_feed.xml")),
          headers: { "Content-Type" => "application/rss+xml" }
        )
    end
  end
end
