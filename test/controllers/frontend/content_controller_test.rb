require "test_helper"

class Frontend::ContentControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get frontend_content_index_url
    assert_response :success
  end
end
