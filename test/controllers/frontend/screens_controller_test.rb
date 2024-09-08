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
    assert_equal screen[:positions].length, 1
    assert screen[:positions][0].has_key?(:id)
    assert_not_empty screen[:positions][0][:content_uri]
  end
end
