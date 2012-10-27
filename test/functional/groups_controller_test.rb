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
    assert_equal assigns(:groups).count, 2
  end

  test "not signed in user can see public group" do
    get :show, :id => groups(:wtg).id
    assert_equal assigns(:group), groups(:wtg)
    assert_response :success
  end

  test "signed in user can see their groups" do
    sign_in users(:katie)
    groups = [groups(:wtg), groups(:rpitv)]
    groups.each do |g|
      get :show, :id => g.id
      assert_equal assigns(:group), g
      assert_response :success
    end
  end
end
