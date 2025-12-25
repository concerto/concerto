require "test_helper"

class ClockPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin_user = users(:system_admin)
    @screen_manager = users(:admin)  # In screen_one_owners group which has screens
    @regular_user = users(:regular)  # Also in screen_one_owners group
    @non_screen_manager = users(:non_member)  # Only in all_users group, no screens
    @clock = clocks(:time_12h)  # Owned by admin user
  end

  # Test creation permissions - restricted to screen managers only

  test "new? is permitted for system admin" do
    assert ClockPolicy.new(@system_admin_user, Clock.new).new?
  end

  test "new? is permitted for screen managers" do
    assert ClockPolicy.new(@screen_manager, Clock.new).new?,
           "Screen managers should be able to create Clock content"
    assert ClockPolicy.new(@regular_user, Clock.new).new?,
           "Regular user who is a screen manager should be able to create Clock content"
  end

  test "new? is denied for users who are not screen managers" do
    refute ClockPolicy.new(@non_screen_manager, Clock.new).new?,
           "Users who don't manage screens should not be able to create Clock content"
  end

  test "new? is denied for anonymous users" do
    refute ClockPolicy.new(nil, Clock.new).new?
  end

  test "create? is permitted for system admin" do
    assert ClockPolicy.new(@system_admin_user, Clock.new).create?
  end

  test "create? is permitted for screen managers" do
    assert ClockPolicy.new(@screen_manager, Clock.new).create?,
           "Screen managers should be able to create Clock content"
    assert ClockPolicy.new(@regular_user, Clock.new).create?,
           "Regular user who is a screen manager should be able to create Clock content"
  end

  test "create? is denied for users who are not screen managers" do
    refute ClockPolicy.new(@non_screen_manager, Clock.new).create?,
           "Users who don't manage screens should not be able to create Clock content"
  end

  test "create? is denied for anonymous users" do
    refute ClockPolicy.new(nil, Clock.new).create?
  end

  # Test edit/update/destroy permissions - inherited from ContentPolicy (owner-based)

  test "edit? is permitted for system admin" do
    assert ClockPolicy.new(@system_admin_user, @clock).edit?
  end

  test "edit? is permitted for clock owner" do
    assert ClockPolicy.new(@screen_manager, @clock).edit?,
           "Clock owner should be able to edit their clock"
  end

  test "edit? is denied for non-owner even if screen manager" do
    # Create a clock owned by non_member
    other_clock = Clock.create!(
      name: "Other Clock",
      duration: 10,
      format: "h:mm a",
      user: @non_screen_manager
    )

    refute ClockPolicy.new(@screen_manager, other_clock).edit?,
           "Screen managers should not be able to edit clocks they don't own"
  end

  test "edit? is denied for anonymous users" do
    refute ClockPolicy.new(nil, @clock).edit?
  end

  test "update? follows same rules as edit?" do
    assert ClockPolicy.new(@system_admin_user, @clock).update?
    assert ClockPolicy.new(@screen_manager, @clock).update?
    refute ClockPolicy.new(@regular_user, @clock).update?
    refute ClockPolicy.new(nil, @clock).update?
  end

  test "destroy? follows same rules as edit?" do
    assert ClockPolicy.new(@system_admin_user, @clock).destroy?
    assert ClockPolicy.new(@screen_manager, @clock).destroy?
    refute ClockPolicy.new(@regular_user, @clock).destroy?
    refute ClockPolicy.new(nil, @clock).destroy?
  end

  test "show? is inherited from ContentPolicy and permits everyone" do
    assert ClockPolicy.new(nil, @clock).show?
    assert ClockPolicy.new(@non_screen_manager, @clock).show?
    assert ClockPolicy.new(@screen_manager, @clock).show?
  end
end
