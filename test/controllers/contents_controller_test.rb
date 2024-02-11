require "test_helper"

class ContentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get contents_url
    assert_response :success
  end

  test "should get new" do
    get new_content_url
    assert_response :success
  end
end
