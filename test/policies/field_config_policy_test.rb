require "test_helper"

class FieldConfigPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @group_admin_user = users(:admin)
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @screen = screens(:one)
    @field_config = field_configs(:with_pinned_content)
  end

  test "index? is permitted for all users" do
    assert FieldConfigPolicy.new(nil, @field_config).index?
    assert FieldConfigPolicy.new(@non_group_user, @field_config).index?
  end

  test "show? is permitted for all users" do
    assert FieldConfigPolicy.new(nil, @field_config).show?
    assert FieldConfigPolicy.new(@non_group_user, @field_config).show?
  end

  test "scope resolves to all field configs" do
    resolved_scope = FieldConfigPolicy::Scope.new(nil, FieldConfig.all).resolve
    assert_equal FieldConfig.all.to_a, resolved_scope.to_a
  end

  # --- Create Tests --- #

  test "new? is permitted for system admin" do
    new_config = FieldConfig.new(screen: @screen, field: fields(:ticker))
    assert FieldConfigPolicy.new(@system_admin_user, new_config).new?
  end

  test "new? is permitted when user can edit the screen" do
    new_config = FieldConfig.new(screen: @screen, field: fields(:ticker))
    assert FieldConfigPolicy.new(@group_admin_user, new_config).new?
    assert FieldConfigPolicy.new(@group_regular_user, new_config).new?
  end

  test "new? is denied when user cannot edit the screen" do
    new_config = FieldConfig.new(screen: @screen, field: fields(:ticker))
    refute FieldConfigPolicy.new(@non_group_user, new_config).new?
  end

  test "create? is permitted for system admin" do
    assert FieldConfigPolicy.new(@system_admin_user, @field_config).create?
  end

  test "create? is permitted when user can update the screen" do
    assert FieldConfigPolicy.new(@group_admin_user, @field_config).create?
    assert FieldConfigPolicy.new(@group_regular_user, @field_config).create?
  end

  test "create? is denied when user cannot update the screen" do
    refute FieldConfigPolicy.new(@non_group_user, @field_config).create?
  end

  # --- Edit/Update Tests --- #

  test "edit? is permitted for system admin" do
    assert FieldConfigPolicy.new(@system_admin_user, @field_config).edit?
  end

  test "edit? is permitted when user can edit the screen" do
    assert FieldConfigPolicy.new(@group_admin_user, @field_config).edit?
    assert FieldConfigPolicy.new(@group_regular_user, @field_config).edit?
  end

  test "edit? is denied when user cannot edit the screen" do
    refute FieldConfigPolicy.new(@non_group_user, @field_config).edit?
  end

  test "update? is permitted for system admin" do
    assert FieldConfigPolicy.new(@system_admin_user, @field_config).update?
  end

  test "update? is permitted when user can update the screen" do
    assert FieldConfigPolicy.new(@group_admin_user, @field_config).update?
    assert FieldConfigPolicy.new(@group_regular_user, @field_config).update?
  end

  test "update? is denied when user cannot update the screen" do
    refute FieldConfigPolicy.new(@non_group_user, @field_config).update?
  end

  # --- Destroy Tests --- #

  test "destroy? is permitted for system admin" do
    assert FieldConfigPolicy.new(@system_admin_user, @field_config).destroy?
  end

  test "destroy? is permitted when user can update the screen" do
    assert FieldConfigPolicy.new(@group_admin_user, @field_config).destroy?
    assert FieldConfigPolicy.new(@group_regular_user, @field_config).destroy?
  end

  test "destroy? is denied when user is not a group member" do
    refute FieldConfigPolicy.new(@non_group_user, @field_config).destroy?
  end

  # --- Permitted Attributes Tests --- #

  test "permitted_attributes includes screen_id, field_id, and pinned_content_id" do
    policy = FieldConfigPolicy.new(@group_admin_user, @field_config)
    attrs = policy.permitted_attributes

    assert_includes attrs, :screen_id
    assert_includes attrs, :field_id
    assert_includes attrs, :pinned_content_id
  end
end
