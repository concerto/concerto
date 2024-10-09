require "test_helper"

class Frontend::ContentControllerTest < ActionDispatch::IntegrationTest
  setup do
    analyze_graphics
  end

  test "should get index" do
    get frontend_content_url(screen_id: screens(:one).id, field_id: fields(:main).id, position_id: positions(:two_graphic).id)
    assert_response :success
    assert_equal response.parsed_body.length, 3
  end
end
