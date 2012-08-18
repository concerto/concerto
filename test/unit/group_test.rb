require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  #Test for duplicate names
  test "name cannot be duplicated" do
    g = groups(:wtg)
    group = Group.new({:name => g.name})
    assert_equal g.name, group.name, "Names are set equal"
    assert !group.valid?, "Names can't be equal"
    group.name = "Fooasdasdasda"
    assert group.valid?, "Unique name is OK"
  end

  #Test has_member?
  test "group has member?" do
    g = groups(:wtg)
    assert g.has_member?(users(:katie)), "Katie is in WTG"
    assert !g.has_member?(users(:kristen)), "Kristen is not in the WTG"
  end

  test "user has permission" do
    g = groups(:wtg)
    u = users(:karen)
    feed_levels = [:all, :submissions, :none]

    membership = memberships(:karen_wtg)
    feed_levels.each do |level|
      membership.perms[:feed] = level
      membership.save

      assert g.user_has_permissions?(u, :supporter, :feed, [level])
      assert g.user_has_permissions?(u, :supporter, :feed, [:all, level])
    end
    assert !g.user_has_permissions?(u, :supporter, :screen, [:all, :subscriptions])
  end
end
