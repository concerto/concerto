require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
  #Test for required associations
  test "membership requires group" do
    blank = Membership.new()
    assert !blank.valid?

    m = Membership.new({:user => users(:kristen)})
    assert !m.valid?, "Membership doesn't have group"
    m.group = groups(:wtg)
    assert m.valid?, "Membership has group"
  end
  test "membership requires user" do
    m = Membership.new({:group => groups(:wtg)})
    assert !m.valid?, "Membership doesn't have user"
    m.user = users(:kristen)
    assert m.valid?, "Membership has user"
  end
  
  #Test for uniqueness
  test "membership cannot duplicate" do
    m = Membership.new({:user => users(:katie), :group => groups(:wtg)})
    assert !m.valid?, "Membership already exists"
    m.user = users(:kristen)
    assert m.valid?, "Membership is unique"
  end

  #Test scoping for leader/regular
  test "leader scope" do
    m = memberships(:katie_wtg)
    leader = Membership.leader
    assert m.is_leader?, "Membership is leader"
    assert_equal leader.length, 1, "Only 1 leader"
    assert_equal leader.first, m, "Membership matches leader"
  end
  test "regular scope" do
    m = memberships(:katie_rpitv)
    regular = Membership.regular
    assert !m.is_leader?, "Membership is not leader"
    assert_equal regular.length, 2, "Only 2 regular"
  end

  # Pending users don't count for membership
  test "pending members aren't in group" do
    wtg = groups(:wtg)
    kristen = users(:kristen)
    assert_no_difference 'wtg.users.count' do
      @m = Membership.new(:user => users(:kristen), :group => groups(:wtg))
      @m.save
    end
    @m.destroy
  end

  test "membership permission compression" do
    m = Membership.new(:level => Membership::LEVELS[:regular])
    assert_equal m.perms, {}

    Membership::PERMISSIONS[:regular][:screen].each do |screen, screen_v|
      Membership::PERMISSIONS[:regular][:feed].each do |feed, feed_v|
        m.perms[:screen] = screen
        m.perms[:feed] = feed
        m.compact_permissions

        permission_string = "0#{m.permissions}"
        assert permission_string.include?(screen_v.to_s), "#{m.permissions} does not have #{screen_v}"
        assert permission_string.include?(feed_v.to_s), "#{m.permissions} does not have #{feed_v}"

        m.perms = {}
        m.expand_permissions

        assert_equal m.perms[:screen], screen
        assert_equal m.perms[:feed], feed
      end
    end   
  end

end
