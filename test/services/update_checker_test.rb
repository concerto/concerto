require "test_helper"

class UpdateCheckerTest < ActiveSupport::TestCase
  GITHUB_URL = "https://api.github.com/repos/concerto/concerto/releases/latest"

  setup do
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  test "fetch_from_github returns tag and url on success" do
    stub_github_success(tag_name: "v3.1.0", html_url: "https://github.com/concerto/concerto/releases/tag/v3.1.0")

    result = UpdateChecker.fetch_from_github

    assert_equal "3.1.0", result[:tag]
    assert_equal "https://github.com/concerto/concerto/releases/tag/v3.1.0", result[:url]
  end

  test "fetch_from_github strips v prefix from tag" do
    stub_github_success(tag_name: "v3.0.0", html_url: "https://example.com")

    result = UpdateChecker.fetch_from_github

    assert_equal "3.0.0", result[:tag]
  end

  test "fetch_from_github returns nil on network error" do
    stub_request(:get, GITHUB_URL).to_raise(SocketError.new("connection refused"))

    result = UpdateChecker.fetch_from_github
    assert_nil result
  end

  test "fetch_from_github returns nil on non-success HTTP response" do
    stub_request(:get, GITHUB_URL).to_return(status: 404, body: "Not Found")

    result = UpdateChecker.fetch_from_github
    assert_nil result
  end

  test "latest_release caches the result" do
    stub_github_success(tag_name: "v3.1.0", html_url: "https://example.com")

    with_memory_cache do
      first = UpdateChecker.latest_release

      # Remove the HTTP stub — a second real call would raise WebMock::NetConnectNotAllowedError
      WebMock.reset!

      second = UpdateChecker.latest_release
      assert_equal first, second
      assert_equal "3.1.0", first[:tag]
    end
  end

  test "latest_release returns nil when fetch fails and nothing is cached" do
    stub_request(:get, GITHUB_URL).to_raise(SocketError.new("connection refused"))

    assert_nil UpdateChecker.latest_release
  end

  test "update_available? returns true when latest tag is newer" do
    stub_github_success(tag_name: "v3.1.0", html_url: "https://example.com")

    with_app_version("3.0.0.dev") do
      assert UpdateChecker.update_available?
    end
  end

  test "update_available? returns false when on same version" do
    stub_github_success(tag_name: "v3.0.0", html_url: "https://example.com")

    with_app_version("3.0.0") do
      assert_not UpdateChecker.update_available?
    end
  end

  test "update_available? returns false when no release info available" do
    stub_request(:get, GITHUB_URL).to_return(status: 404, body: "Not Found")

    assert_not UpdateChecker.update_available?
  end

  private

  def stub_github_success(tag_name:, html_url:)
    body = JSON.generate({ "tag_name" => tag_name, "html_url" => html_url })
    stub_request(:get, GITHUB_URL).to_return(
      status: 200,
      body: body,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def with_memory_cache
    old_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = old_cache
  end

  def with_app_version(version)
    old = Object.const_get(:APP_VERSION)
    Object.send(:remove_const, :APP_VERSION)
    Object.const_set(:APP_VERSION, version)
    yield
  ensure
    Object.send(:remove_const, :APP_VERSION)
    Object.const_set(:APP_VERSION, old)
  end
end
