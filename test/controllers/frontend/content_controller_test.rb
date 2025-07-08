require "test_helper"

class Frontend::ContentControllerTest < ActionDispatch::IntegrationTest
  test "should get main content" do
    get frontend_content_url(screen_id: screens(:one).id, field_id: fields(:main).id, position_id: positions(:two_graphic).id)
    assert_response :success
    assert_equal 1, response.parsed_body.length
  end

  test "should get ticker content" do
    get frontend_content_url(screen_id: screens(:two).id, field_id: fields(:ticker).id, position_id: positions(:two_ticker).id)
    assert_response :success
    assert_equal 2, response.parsed_body.length
  end
end
