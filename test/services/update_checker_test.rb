require "test_helper"

class UpdateCheckerTest < ActiveSupport::TestCase
  GITHUB_URL = "https://api.github.com/repos/concerto/concerto/releases/latest"

  # fetch_from_github tests make real (stubbed) HTTP calls and are not affected
  # by the Rails.env.test? guard in latest_release.

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

    assert_nil UpdateChecker.fetch_from_github
  end

  test "fetch_from_github returns nil on non-success HTTP response" do
    stub_request(:get, GITHUB_URL).to_return(status: 404, body: "Not Found")

    assert_nil UpdateChecker.fetch_from_github
  end

  # update_available? stubs latest_release directly since latest_release
  # skips the HTTP call in the test environment.

  test "update_available? returns true when latest tag is newer" do
    UpdateChecker.stub(:latest_release, { tag: "3.1.0", url: "https://example.com" }) do
      with_app_version("3.0.0.dev") do
        assert UpdateChecker.update_available?
      end
    end
  end

  test "update_available? returns false when on same version" do
    UpdateChecker.stub(:latest_release, { tag: "3.0.0", url: "https://example.com" }) do
      with_app_version("3.0.0") do
        assert_not UpdateChecker.update_available?
      end
    end
  end

  test "update_available? returns false when no release info available" do
    UpdateChecker.stub(:latest_release, nil) do
      assert_not UpdateChecker.update_available?
    end
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
