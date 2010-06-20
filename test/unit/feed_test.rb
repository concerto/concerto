require 'test_helper'

class FeedTest < ActiveSupport::TestCase
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
  
  # The ancestor tree is build and in order
  test "feed ancestors" do
    assert feeds(:service).ancestors.empty?
    
    assert feeds(:announcements).ancestors.empty?
    
    assert_equal feeds(:boring_announcements).ancestors, [feeds(:announcements)]
    assert_equal feeds(:sleepy_announcements).ancestors, [feeds(:boring_announcements), feeds(:announcements)]
  end
  
  # Descendants are build, no order preference
  test "feed descendants" do
    assert feeds(:service).descendants.empty?
    
    assert feeds(:announcements).descendants.size, 3
    assert feeds(:announcements).descendants.include?(feeds(:boring_announcements))
    assert feeds(:announcements).descendants.include?(feeds(:sleepy_announcements))
    assert feeds(:announcements).descendants.include?(feeds(:important_announcements))
    
    assert_equal feeds(:boring_announcements).descendants, [feeds(:sleepy_announcements)]
  end
end
