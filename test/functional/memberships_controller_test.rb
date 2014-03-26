require 'test_helper'

class MembershipsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "should create pending membership" do
    sign_in users(:kristen)
    assert_difference('Membership.count', 1) do
      post :create, {:membership => {:user_id => users(:kristen).id}, :group_id => groups(:wtg).id}
    end
    actual = assigns(:membership)
    group = assigns(:group)
    assert_equal(Membership::LEVELS[:pending], actual.level)
    assert_redirected_to group_path(group)
  end

  test "should autoaprove members added by admins" do
    sign_in users(:katie)
    assert_difference('Membership.count', 1) do
      post :create, {:membership => {:user_id => users(:kristen).id}, :group_id => groups(:wtg).id, :autoconfirm => true}
    end
    actual = assigns(:membership)
    group = assigns(:group)
    assert_equal(Membership::LEVELS[:regular], actual.level)
    assert_redirected_to manage_members_group_path(group)
  end

end
