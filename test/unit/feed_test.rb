require 'test_helper'

class FeedTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "name cannot be blank" do
    f = feeds(:one)
    feed = Feed.new(f.attributes)
    feed.name = ""
    assert !feed.valid?, "Feed name is blank"
    feed.name = "Blah"
    assert feed.valid?, "Feed name has entry"
  end
  
  #Test for duplicate names
  test "name cannot be duplicated" do
    f = feeds(:one)
    feed = Feed.new({:name => f.name})
    assert_equal f.name, feed.name, "Names are set equal"
    assert !feed.valid?, "Names can't be equal"
    feed.name = "Fooasdasdasda"
    assert feed.valid?, "Unique name is OK"
  end
end
