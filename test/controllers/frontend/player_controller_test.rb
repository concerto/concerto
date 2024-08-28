require "test_helper"

class Frontend::PlayerControllerTest < ActionDispatch::IntegrationTest
  setup do
    @screen = screens(:one)
  end


  test "should show screen" do
    get "/frontend/#{@screen.id}"
    assert_response :success
  end
end
