require "test_helper"

class RemoteFeedPolicyTest < ActiveSupport::TestCase
  setup do
    @system_admin = users(:system_admin)
    @group_admin = users(:admin)
    @group_member = users(:regular)
    @non_member = users(:non_member)

    @remote_feed = remote_feeds(:test_remote_feed)
  end

  test "permitted_attributes_for_show includes url for system admin" do
    policy = RemoteFeedPolicy.new(@system_admin, @remote_feed)
    assert_includes policy.permitted_attributes_for_show, :url
  end

  test "permitted_attributes_for_show includes url for group admin" do
    policy = RemoteFeedPolicy.new(@group_admin, @remote_feed)
    assert_includes policy.permitted_attributes_for_show, :url
  end

  test "permitted_attributes_for_show includes url for group member (who can edit)" do
    policy = RemoteFeedPolicy.new(@group_member, @remote_feed)
    assert_includes policy.permitted_attributes_for_show, :url
  end

  test "permitted_attributes_for_show excludes url for non-member" do
    policy = RemoteFeedPolicy.new(@non_member, @remote_feed)
    assert_not_includes policy.permitted_attributes_for_show, :url
  end

  test "permitted_attributes_for_show excludes url for anonymous user" do
    policy = RemoteFeedPolicy.new(nil, @remote_feed)
    assert_not_includes policy.permitted_attributes_for_show, :url
  end

  test "permitted_attributes_for_show always includes safe attributes" do
    policy = RemoteFeedPolicy.new(@non_member, @remote_feed)
    safe_attrs = [ :id, :name, :description, :type, :group_id, :created_at, :updated_at, :last_refreshed ]
    safe_attrs.each do |attr|
      assert_includes policy.permitted_attributes_for_show, attr, "Expected #{attr} to be included for non-members"
    end
  end
end
