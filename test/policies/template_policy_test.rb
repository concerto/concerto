require "test_helper"

class TemplatePolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)  # Admin of screen_one_owners group
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @template = templates(:one)
  end

  test "scope returns all templates for everyone" do
    resolved_scope = TemplatePolicy::Scope.new(nil, Template.all).resolve
    assert_equal Template.all.to_a, resolved_scope.to_a

    resolved_scope = TemplatePolicy::Scope.new(@group_regular_user, Template.all).resolve
    assert_equal Template.all.to_a, resolved_scope.to_a
  end

  test "index? is permitted for everyone" do
    assert TemplatePolicy.new(nil, Template).index?
    assert TemplatePolicy.new(@non_group_user, Template).index?
  end

  test "show? is permitted for everyone" do
    assert TemplatePolicy.new(nil, @template).show?
    assert TemplatePolicy.new(@non_group_user, @template).show?
  end

  test "new? is permitted for system admin" do
    assert TemplatePolicy.new(@system_admin_user, Template.new).new?
  end

  test "new? is permitted for user who is an admin of a group owning a screen" do
    assert TemplatePolicy.new(@group_admin_user, Template.new).new?
  end

  test "new? is denied for user who is not an admin of a group owning a screen" do
    refute TemplatePolicy.new(@group_regular_user, Template.new).new?
    refute TemplatePolicy.new(@non_group_user, Template.new).new?
  end

  test "create? is permitted for system admin" do
    assert TemplatePolicy.new(@system_admin_user, Template.new).create?
  end

  test "create? is permitted for user who is an admin of a group owning a screen" do
    assert TemplatePolicy.new(@group_admin_user, Template.new).create?
  end

  test "create? is denied for user who is not an admin of a group owning a screen" do
    refute TemplatePolicy.new(@group_regular_user, Template.new).create?
    refute TemplatePolicy.new(@non_group_user, Template.new).create?
  end

  test "edit? is permitted for system admin only" do
    assert TemplatePolicy.new(@system_admin_user, @template).edit?
  end

  test "edit? is denied for non-system admin" do
    refute TemplatePolicy.new(@group_admin_user, @template).edit?
    refute TemplatePolicy.new(@non_group_user, @template).edit?
  end

  test "update? is permitted for system admin only" do
    assert TemplatePolicy.new(@system_admin_user, @template).update?
  end

  test "update? is denied for non-system admin" do
    refute TemplatePolicy.new(@group_admin_user, @template).update?
    refute TemplatePolicy.new(@non_group_user, @template).update?
  end

  test "destroy? is permitted for system admin only" do
    assert TemplatePolicy.new(@system_admin_user, @template).destroy?
  end

  test "destroy? is denied for non-system admin" do
    refute TemplatePolicy.new(@group_admin_user, @template).destroy?
    refute TemplatePolicy.new(@non_group_user, @template).destroy?
  end
end
