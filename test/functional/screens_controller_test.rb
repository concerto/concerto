require 'test_helper'

class ScreensControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "not signed in user has no personal screens" do
    get :index, params: {}
    assert assigns(:my_screens)
    assert_equal [], assigns(:my_screens)
    assert_equal [screens(:two)], assigns(:screens)
  end

  test "signed in user has personal screens" do
    sign_in users(:katie)
    get :index, params: {}
    assert assigns(:my_screens)
    assert_equal 4, assigns(:my_screens).count
    assert_equal 4, assigns(:screens).count
  end
end
