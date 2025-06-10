require "test_helper"

class UsersHelperTest < ActionView::TestCase
  test "user_initials returns first and last initial when name is present" do
    user = users(:admin) # Using the admin fixture which has first_name: 'Admin', last_name: 'User'
    assert_equal "AU", user_initials(user)
  end

  test "user_initials returns first letter of email when name is not present" do
    user = users(:admin)
    user.first_name = nil
    user.last_name = nil
    assert_equal "A", user_initials(user) # admin@concerto.test
  end
end
