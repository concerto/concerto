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
    leader = Membership.leader.all
    assert m.is_leader?, "Membership is leader"
    assert_equal 1, leader.length, "Only 1 leader"
    assert_equal m, leader.first, "Membership matches leader"
  end
  test "regular scope" do
    m = memberships(:katie_rpitv)
    regular = Membership.regular.all
    assert !m.is_leader?, "Membership is not leader"
    assert_equal 2, regular.length, "Only 2 regular"
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
    assert_equal({}, m.perms)

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

        assert_equal screen, m.perms[:screen]
        assert_equal feed, m.perms[:feed]
      end
    end   
  end

  test "is_denied? reflects members that have level 0" do
    assert memberships(:kristen_rpitv).is_denied?
    assert !memberships(:katie_wtg).is_denied?
    assert !memberships(:karen_wtg).is_denied?
    assert !memberships(:kristen_unused).is_denied?
  end

  test "is_pending? reflects members that are pending" do
    assert !memberships(:kristen_rpitv).is_pending?
    assert !memberships(:katie_wtg).is_pending?
    assert !memberships(:karen_wtg).is_pending?
    assert memberships(:kristen_unused).is_pending?
  end

  test "is_approved? reflects members not pending or denied" do
    assert !memberships(:kristen_rpitv).is_approved?
    assert memberships(:katie_wtg).is_approved?
    assert memberships(:karen_wtg).is_approved?
    assert !memberships(:kristen_unused).is_approved?
  end

  test "sole leader cannot resign leadership" do
    assert !memberships(:katie_wtg).can_resign_leadership?
  end

  test "non-leader cannot resign leadership" do
    assert !memberships(:karen_wtg).can_resign_leadership?
  end

  test "leader can resign if other leaders present" do
    memberships(:karen_wtg).update_membership_level('promote')
    assert memberships(:katie_wtg).can_resign_leadership?
  end

  test "can deny only pending memberships" do
    result, msg = memberships(:karen_wtg).update_membership_level('deny')
    assert !result
    result, msg = memberships(:katie_wtg).update_membership_level('deny')
    assert !result
    result, msg = memberships(:kristen_rpitv).update_membership_level('deny')
    assert !result
    result, msg = memberships(:kristen_unused).update_membership_level('deny')
    assert result
  end

  test "can approve only pending memberships" do
    result, msg = memberships(:karen_wtg).update_membership_level('approve')
    assert !result
    result, msg = memberships(:katie_wtg).update_membership_level('approve')
    assert !result
    result, msg = memberships(:kristen_rpitv).update_membership_level('approve')
    assert !result
    result, msg = memberships(:kristen_unused).update_membership_level('approve')
    assert result
  end

  test "can demote only leaders and only when more than one exists" do
    result, msg = memberships(:katie_wtg).update_membership_level('demote')
    assert !result

    result, msg = memberships(:karen_wtg).update_membership_level('demote')
    assert !result

    memberships(:karen_wtg).update_membership_level('promote')
    result, msg = memberships(:katie_wtg).update_membership_level('demote')
    assert result
  end

end
