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

  test "destroying user destroys associated contents" do
    # Create a dedicated user for this test
    test_user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test@example.com",
      password: "password123"
    )

    # Create some content associated with the test user
    rich_text1 = RichText.create!(name: "Test Rich Text 1", duration: 30, text: "Test content 1", config: { 'render_as': "plaintext" }, user: test_user)
    rich_text2 = RichText.create!(name: "Test Rich Text 2", duration: 60, text: "Test content 2", config: { 'render_as': "plaintext" }, user: test_user)

    # Verify content exists and is associated with the user
    assert_equal 2, test_user.contents.count
    assert_includes test_user.contents, rich_text1
    assert_includes test_user.contents, rich_text2

    # Store content IDs to check they're destroyed
    rich_text1_id = rich_text1.id
    rich_text2_id = rich_text2.id

    # Destroy the user
    test_user.destroy

    # Verify associated content was also destroyed
    assert_nil Content.find_by(id: rich_text1_id)
    assert_nil Content.find_by(id: rich_text2_id)
  end
end
