require 'test_helper'

class ScreensControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "not signed in user has no personal screens" do
    get :index
    assert assigns(:my_screens)
    assert_equal assigns(:my_screens), []
    assert_equal assigns(:screens), [screens(:two)]
  end

  test "signed in user has personal screens" do
    sign_in users(:katie)
    get :index
    assert assigns(:my_screens)
    assert_equal assigns(:my_screens).count, 3
    assert_equal assigns(:screens).count, 3
  end
end
