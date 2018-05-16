require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  test 'not signed in user has no personal groups' do
    get :index
    assert assigns(:my_groups)
    assert_equal [], assigns(:my_groups)
    assert_equal 1, assigns(:groups).count # This is a 1 because the other group has no reason to be public.
  end

  test 'signed in user has personal groups' do
    sign_in users(:katie)
    get :index
    assert assigns(:my_groups)
    assert_equal 2, assigns(:my_groups).count
    assert_equal 2, assigns(:groups).count
  end

  test 'not signed in user can see public group' do
    get :show, id: groups(:wtg).id
    assert_equal groups(:wtg), assigns(:group)
    assert_response :success
  end

  test 'admin can add new group' do
    sign_in users(:admin)
    get :new
    assert_response :success
    assert assigns(:group)
  end

  test 'admin can manage members' do
    sign_in users(:admin)
    get :manage_members, id: groups(:rpitv).id
    assert_response :success
    assert assigns(:group)
    assert_equal 1, assigns(:denied).count
  end

  test 'regular member cannot manage members' do
    sign_in users(:katie)
    get :manage_members, id: groups(:rpitv).id
    assert_redirected_to root_path
  end

  test 'leader can edit group' do
    sign_in users(:katie)
    g = groups(:wtg)
    get :edit, id: g.id
    assert_response :success
    assert assigns(:group)
  end

  test 'leader can update group' do
    sign_in users(:katie)
    g = groups(:wtg)
    g.name = 'name changed'
    put :update, id: g.id, group: { name: g.name }
    assert assigns(:group)
    assert_redirected_to group_path(g)
  end

  test 'regular member cannot edit group' do
    sign_in users(:katie)
    g = groups(:rpitv)
    get :edit, id: g.id
    assert_redirected_to root_path
  end

  test 'admin can create group' do
    sign_in users(:admin)
    assert_difference('Group.count') do
      post :create, group: {
        name: 'a new group'
      }
    end
    g = assigns(:group)
    assert_redirected_to group_path(g.id)
  end

  test 'can destroy group' do
    sign_in users(:admin)
    g = groups(:unused)
    assert_difference('Group.count', -1) do
      delete :destroy, id: g.id
    end
    assert_redirected_to groups_path
  end

  test 'cannot destroy group with screens' do
    sign_in users(:admin)
    g = groups(:wtg)
    assert_difference('Group.count', 0) do
      delete :destroy, id: g.id
    end
    assert_redirected_to group_path(g)
  end

  test 'signed in user can see their groups' do
    sign_in users(:katie)
    groups = [groups(:wtg), groups(:rpitv)]
    groups.each do |g|
      get :show, id: g.id
      assert_equal g, assigns(:group)
      assert_response :success
    end
  end
end
