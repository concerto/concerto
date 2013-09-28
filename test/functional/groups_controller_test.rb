require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "not signed in user has no personal groups" do
    get :index
    assert assigns(:my_groups)
    assert_equal [], assigns(:my_groups)
    assert_equal 1, assigns(:groups).count # This is a 1 because the other group has no reason to be public.
  end

  test "signed in user has personal groups" do
    sign_in users(:katie)
    get :index
    assert assigns(:my_groups)
    assert_equal 2, assigns(:my_groups).count
    assert_equal 2, assigns(:groups).count
  end

  test "not signed in user can see public group" do
    get :show, :id => groups(:wtg).id
    assert_equal groups(:wtg), assigns(:group)
    assert_response :success
  end

  test "signed in user can see their groups" do
    sign_in users(:katie)
    groups = [groups(:wtg), groups(:rpitv)]
    groups.each do |g|
      get :show, :id => g.id
      assert_equal g, assigns(:group)
      assert_response :success
    end
  end
end
