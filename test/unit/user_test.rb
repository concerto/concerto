require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Test for duplicate names
  test "username cannot be duplicated" do
    u = users(:katie)
    user = User.new({:username => u.username, :email => "test@a.com"})
    assert_equal user.username, u.username, "Usernames are set equal"
    assert !user.valid?, "Usernames can't be equal"
    user.username = "Fooasdasdasda"
    assert user.valid?, "Unique username is OK"
  end
  
  # Test for duplicate email
  test "email cannot be duplicated" do
    u = users(:katie)
    user = User.new({:username => "Test123", :email => u.email})
    assert_equal user.email, u.email, "Emails are set equal"
    assert !user.valid?, "Emails can't be equal"
    user.email = "Fooasdasdasda@test.com"
    assert user.valid?, "Unique emails is OK"
  end

  # Test the in_group? functionality which should determine
  # if a user is in a group or not.
  test "users in groups?" do
    g = groups(:rpitv)
    assert users(:katie).in_group?(g), "Katie is in RPITV"
    assert !users(:kristen).in_group?(g), "Kristen is not in RPITV"
  end
end
