require 'test_helper'

class FeedTest < ActiveSupport::TestCase
  def setup
    @public = feeds(:service)
    @hidden = feeds(:secret_announcements)
  end

  # Attributes cannot be left empty/blank
  test "feed attributes must not be empty" do
    feed = Feed.new
    assert feed.invalid?
    assert feed.errors[:name].any?
    assert feed.errors[:group].any?
  end

  # The feed name must be unique
  test "feed is now valid without a unique name" do
    feed = Feed.new(:name => feeds(:service).name,
                    :description => "Another feed.",
                    :group => groups(:rpitv))

    assert feed.invalid?
    assert feed.errors[:name].any?
  end


  # Feed Hierachy Tests

  # Verify the root scope returns all root feeds.
  test "feed root scope" do
    roots = Feed.roots
    roots.each do |feed|
      assert feed.is_root?
    end
  end

  # A child feed should have a parent
  test "feed parent relationship" do
    assert_nil feeds(:announcements).parent
    assert_equal feeds(:boring_announcements).parent, feeds(:announcements)
  end

  # A feed should have children
  test "feed child relationship" do
    assert feeds(:service).children.empty?

    assert feeds(:announcements).children.include?(feeds(:boring_announcements))
    assert feeds(:announcements).children.include?(feeds(:important_announcements))

    assert_equal feeds(:boring_announcements).children, [feeds(:sleepy_announcements)]
  end

  # A root feed is_root?
  test "feed is_root?" do
    assert feeds(:service).is_root?
    assert !feeds(:boring_announcements).is_root?
  end

  # A feed cannot be it's own parent
  test "that a feed cannot be it's own parent" do
    feed = feeds(:boring_announcements)
    feed.update_attribute(:parent_id, feed.id)
    assert feed.invalid?
    assert feed.errors[:parent_id].any?
  end

  # The ancestor tree is built and in order
  test "feed ancestors" do
    assert feeds(:service).ancestors.empty?

    assert feeds(:announcements).ancestors.empty?

    assert_equal feeds(:boring_announcements).ancestors, [feeds(:announcements)]
    assert_equal feeds(:sleepy_announcements).ancestors, [feeds(:boring_announcements), feeds(:announcements)]
  end

  # Descendants are built and in order
  test "feed descendants" do
    assert feeds(:service).descendants.empty?

    assert_equal feeds(:announcements).descendants.size, 3
    assert feeds(:announcements).descendants.include?(feeds(:boring_announcements))
    assert feeds(:announcements).descendants.include?(feeds(:sleepy_announcements))
    assert feeds(:announcements).descendants.include?(feeds(:important_announcements))

    feed_list = [feeds(:boring_announcements), feeds(:sleepy_announcements), feeds(:important_announcements)]
    assert_equal feeds(:announcements).descendants, feed_list

    assert_equal feeds(:boring_announcements).descendants, [feeds(:sleepy_announcements)]
  end

  # Test feed depth
  test "feed depth" do
    assert_equal feeds(:service).depth, 0
    assert_equal feeds(:announcements).depth, 0

    assert_equal feeds(:sleepy_announcements).depth, 2
  end

  # Self and siblings works for children and roots
  test "self and siblings" do
    roots = Feed.roots
    roots.each do |root|
      roots.each do |sibling|
        assert root.self_and_siblings.include?(sibling)
      end
    end

    assert_equal feeds(:boring_announcements).self_and_siblings.size, 2
    assert feeds(:boring_announcements).self_and_siblings.include?(feeds(:boring_announcements))
    assert feeds(:boring_announcements).self_and_siblings.include?(feeds(:important_announcements))

    assert_equal feeds(:sleepy_announcements).self_and_siblings.size, 1
    assert feeds(:sleepy_announcements).self_and_siblings.include?(feeds(:sleepy_announcements))
  end

  test "subscribable lists unsubscribed feeds" do
    f = Feed.subscribable(screens(:one), fields(:one))
    assert f.include?(feeds(:secret_announcements))
    assert !f.include?(feeds(:announcements))
  end
end
