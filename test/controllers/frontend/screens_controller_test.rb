require "test_helper"

class Frontend::ScreensControllerTest < ActionDispatch::IntegrationTest
  def setup
    @screen = screens(:one)
  end

  test "should get show" do
    get frontend_screen_url(id: @screen.id, format: :json)
    assert_response :success

    screen = response.parsed_body
    assert_not_empty screen[:template][:background_uri]
    assert_equal 4, screen[:positions].length
    assert screen[:positions][0].has_key?(:id)
    assert_not_empty screen[:positions][0][:content_uri]
  end

  test "should include config version header" do
    get frontend_screen_url(id: @screen.id, format: :json)
    assert_response :success

    config_version = response.headers["X-Config-Version"]
    assert_not_nil config_version
    assert_equal 32, config_version.length
    assert_match(/^[a-f0-9]{32}$/, config_version)
  end
end
