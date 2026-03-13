require "test_helper"

class UpdateCheckerTest < ActiveSupport::TestCase
  GITHUB_LATEST_URL = "https://api.github.com/repos/concerto/concerto/releases/latest"
  GITHUB_RELEASES_URL = "https://api.github.com/repos/concerto/concerto/releases?per_page=1"

  setup do
    Setting[:update_prerelease] = false
  end

  test "fetch_from_github returns tag and url on success" do
    stub_github_latest(tag_name: "v3.1.0", html_url: "https://github.com/concerto/concerto/releases/tag/v3.1.0")

    result = UpdateChecker.fetch_from_github

    assert_equal "3.1.0", result[:tag]
    assert_equal "https://github.com/concerto/concerto/releases/tag/v3.1.0", result[:url]
  end

  test "fetch_from_github strips v prefix from tag" do
    stub_github_latest(tag_name: "v3.0.0", html_url: "https://example.com")

    result = UpdateChecker.fetch_from_github

    assert_equal "3.0.0", result[:tag]
  end

  test "fetch_from_github returns nil on network error" do
    stub_request(:get, GITHUB_LATEST_URL).to_raise(SocketError.new("connection refused"))

    assert_nil UpdateChecker.fetch_from_github
  end

  test "fetch_from_github returns nil on non-success HTTP response" do
    stub_request(:get, GITHUB_LATEST_URL).to_return(status: 404, body: "Not Found")

    assert_nil UpdateChecker.fetch_from_github
  end

  test "update_available? returns true when latest tag is newer" do
    stub_github_latest(tag_name: "v3.1.0", html_url: "https://example.com")

    stub_const(Object, :APP_VERSION, "3.0.0.dev") do
      assert UpdateChecker.update_available?
    end
  end

  test "update_available? returns false when on same version" do
    stub_github_latest(tag_name: "v3.0.0", html_url: "https://example.com")

    stub_const(Object, :APP_VERSION, "3.0.0") do
      assert_not UpdateChecker.update_available?
    end
  end

  test "update_available? returns false when no release info available" do
    stub_request(:get, GITHUB_LATEST_URL).to_return(status: 404, body: "Not Found")

    assert_not UpdateChecker.update_available?
  end

  # Pre-release tests

  test "fetch_from_github uses all releases endpoint when prerelease setting enabled" do
    Setting[:update_prerelease] = true
    stub_github_all_releases(tag_name: "v3.2.0-beta.1", html_url: "https://example.com/beta", prerelease: true)

    result = UpdateChecker.fetch_from_github

    assert_equal "3.2.0-beta.1", result[:tag]
    assert_equal "https://example.com/beta", result[:url]
    assert result[:prerelease]
  end

  test "fetch_from_github uses latest endpoint when prerelease setting disabled" do
    Setting[:update_prerelease] = false
    stub_github_latest(tag_name: "v3.1.0", html_url: "https://example.com/stable")

    result = UpdateChecker.fetch_from_github

    assert_equal "3.1.0", result[:tag]
    assert_nil result[:prerelease]
  end

  test "prerelease fetch returns nil on empty releases array" do
    Setting[:update_prerelease] = true
    stub_request(:get, GITHUB_RELEASES_URL).to_return(
      status: 200,
      body: "[]",
      headers: { "Content-Type" => "application/json" }
    )

    assert_nil UpdateChecker.fetch_from_github
  end

  test "prerelease fetch returns nil on API failure" do
    Setting[:update_prerelease] = true
    stub_request(:get, GITHUB_RELEASES_URL).to_return(status: 404, body: "Not Found")

    assert_nil UpdateChecker.fetch_from_github
  end

  test "update_available? works with prerelease versions" do
    Setting[:update_prerelease] = true
    stub_github_all_releases(tag_name: "v3.2.0-rc.1", html_url: "https://example.com", prerelease: true)

    stub_const(Object, :APP_VERSION, "3.1.0") do
      assert UpdateChecker.update_available?
    end
  end

  test "include_prerelease? returns false when setting does not exist" do
    Setting.find_by(key: "update_prerelease")&.destroy

    assert_not UpdateChecker.include_prerelease?
  end

  private

  def stub_github_latest(tag_name:, html_url:)
    body = JSON.generate({ "tag_name" => tag_name, "html_url" => html_url })
    stub_request(:get, GITHUB_LATEST_URL).to_return(
      status: 200,
      body: body,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_github_all_releases(tag_name:, html_url:, prerelease: false)
    body = JSON.generate([ { "tag_name" => tag_name, "html_url" => html_url, "prerelease" => prerelease } ])
    stub_request(:get, GITHUB_RELEASES_URL).to_return(
      status: 200,
      body: body,
      headers: { "Content-Type" => "application/json" }
    )
  end
end
