require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "not signed in user has no personal groups" do
    get :index
    assert assigns(:my_groups)
    assert_equal assigns(:my_groups), []
    assert_equal assigns(:groups).count, 1 # This is a 1 because the other group has no reason to be public.
  end

  test "signed in user has personal groups" do
    sign_in users(:katie)
    get :index
    assert assigns(:my_groups)
    assert_equal assigns(:my_groups).count, 2
    assert_equal assigns(:groups).count, 0
  end
end
