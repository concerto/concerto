require 'test_helper'

class Frontend::ScreensControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :screens

  test "should get screen frontend" do
    get(:show, {:id => screens(:one).id})
    assert_response :success
    assert_template false
  end

  test "should get screen setup" do
    get(:setup, {:id => screens(:one).id, :format => :json})
    assert_response :success
  end

end
