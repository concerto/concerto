require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    membership = Membership.new(
      user: users(:regular),
      group: groups(:moderators), # Use a group that doesn't already have this user
      role: :member
    )
    assert membership.valid?
  end

  test "should require user" do
    membership = Membership.new(group: groups(:content_creators), role: :member)
    assert_not membership.valid?
    assert_includes membership.errors[:user], "must exist"
  end

  test "should require group" do
    membership = Membership.new(user: users(:regular), role: :member)
    assert_not membership.valid?
    assert_includes membership.errors[:group], "must exist"
  end

  test "should require role" do
    membership = Membership.new(user: users(:regular), group: groups(:moderators))
    # Role is required by the database constraint
    assert_raises(ActiveRecord::NotNullViolation) do
      membership.role = nil
      membership.save!
    end
  end

  test "should enforce unique user-group combination" do
    existing = memberships(:admin_content_creator)
    duplicate = Membership.new(
      user: existing.user,
      group: existing.group,
      role: :member
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "should have member and admin roles" do
    membership = Membership.new
    assert_includes Membership.roles.keys, "member"
    assert_includes Membership.roles.keys, "admin"
  end

  test "should belong to user and group" do
    membership = memberships(:admin_content_creator)
    assert_respond_to membership, :user
    assert_respond_to membership, :group
    assert_equal users(:admin), membership.user
    assert_equal groups(:content_creators), membership.group
  end

  test "should prevent removal from system group" do
    system_membership = memberships(:admin_in_all_users)
    # The validation should prevent destruction
    assert_not system_membership.destroy
    assert system_membership.errors[:base].any?
  end

  test "should allow removal from regular groups" do
    regular_membership = memberships(:admin_content_creator)
    assert regular_membership.destroy
  end
end
