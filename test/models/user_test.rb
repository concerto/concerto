require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "requires first name" do
    @user.first_name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:first_name], "can't be blank"
  end

  test "requires last name" do
    @user.last_name = nil
    assert_not @user.valid?
    assert_includes @user.errors[:last_name], "can't be blank"
  end

  test "full_name combines first and last name" do
    assert_equal "Admin User", @user.full_name
  end

  test "display_name uses full name when available" do
    assert_equal "Admin User", @user.display_name
  end

  test "display_name falls back to email when name not available" do
    @user.first_name = nil
    @user.last_name = nil
    assert_equal @user.email, @user.display_name
  end
end
