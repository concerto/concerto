require "test_helper"

class Frontend::PlayerControllerTest < ActionDispatch::IntegrationTest
  SUPPORTED_USER_AGENTS = {
    "Chrome 64" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36",
    "Firefox 69" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:69.0) Gecko/20100101 Firefox/69.0",
    "Safari 13.1" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1 Safari/605.1.15",
    "LG Smart TV Chrome 79" => "Mozilla/5.0 (Linux; NetCast; U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.79 Safari/537.36 SmartTV/10.0 Colt/2.0",
    # Older LG WebOS screens (issue #1927). Served the SystemJS legacy bundle
    # since they lack native ES modules. Chrome 53 is the supported floor.
    "LG WebOS Chrome 53" => "Mozilla/5.0 (Linux; NetCast; U) AppleWebKit/537.31 (KHTML, like Gecko) Chrome/53.0.2785.34 Safari/537.31 SmartTV/6.0",
    "Chrome 63" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36"
  }.freeze

  UNSUPPORTED_USER_AGENTS = {
    "Chrome 52" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36",
    "Firefox 68" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:68.0) Gecko/20100101 Firefox/68.0",
    "Safari 13.0" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Safari/605.1.15"
  }.freeze

  setup do
    @screen = screens(:one)
  end

  test "should show screen" do
    get "/frontend/#{@screen.id}"
    assert_response :success
  end

  test "renders the legacy SystemJS fallback bundle for old browsers" do
    # The vite_plugin_legacy helper must resolve the manifest and emit <script
    # nomodule> tags so browsers without native ES modules (e.g. Chrome 53 on
    # older WebOS screens, issue #1927) fall back to the SystemJS bundle.
    get "/frontend/#{@screen.id}"
    assert_response :success
    assert_select "script[nomodule]", minimum: 1
    assert_match(/player-legacy/, response.body,
      "legacy player bundle not referenced in the page")
  end

  SUPPORTED_USER_AGENTS.each do |name, user_agent|
    test "should show screen with supported browser #{name}" do
      get "/frontend/#{@screen.id}", headers: { "User-Agent" => user_agent }
      assert_response :success
    end
  end

  UNSUPPORTED_USER_AGENTS.each do |name, user_agent|
    test "should reject unsupported browser #{name}" do
      get "/frontend/#{@screen.id}", headers: { "User-Agent" => user_agent }
      assert_response :not_acceptable
      assert_select "h1", "Browser Not Supported"
    end
  end
end
