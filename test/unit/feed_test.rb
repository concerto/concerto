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
 
end
