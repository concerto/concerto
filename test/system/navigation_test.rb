require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "displays sign in button when user is not authenticated" do
    visit feeds_path
    
    assert_selector "nav" do
      assert_link "Sign in", href: new_user_session_path
      assert_no_selector "button#user-menu-button"
    end
  end

  test "displays user avatar and menu when user is authenticated" do
    user = users(:admin)
    sign_in user
    visit feeds_path

    assert_selector "nav" do
      assert_selector "#user-menu-button"
      assert_selector ".rounded-full", text: user.email[0].upcase
      assert_no_link "Sign in"
    end

    # Test dropdown functionality
    find("#user-menu-button").click
    assert_selector "[role='menu']" do
      assert_link "Sign Out"
      assert_link "Your Profile"
      assert_link "Settings"
    end
  end

  test "mobile menu shows correct authentication state" do
    # Set mobile viewport size
    page.driver.browser.manage.window.resize_to(375, 667)
    
    visit feeds_path
    
    # Test unauthenticated state
    find("button[aria-controls='mobile-menu']").click
    within "#mobile-menu" do
      assert_link "Sign in"
      assert_no_selector ".text-white", text: /@/
    end

    # Test authenticated state
    user = users(:admin)
    sign_in user
    visit feeds_path
    
    find("button[aria-controls='mobile-menu']").click
    within "#mobile-menu" do
      assert_selector ".text-white", text: user.email
      assert_selector ".rounded-full", text: user.email[0].upcase
      assert_link "Sign out"
    end
  end
end
