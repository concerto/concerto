require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  test "displays sign in button when user is not authenticated" do
    # Set desktop viewport size
    page.driver.browser.manage.window.resize_to(1024, 680)

    visit feeds_path

    # Check header authentication state
    assert_selector "header" do
      assert_link "Sign In", href: new_user_session_path
      assert_no_selector "[data-controller='dropdown']"
    end
  end

  test "displays user avatar and menu when user is authenticated" do
    # Set desktop viewport size
    page.driver.browser.manage.window.resize_to(1024, 680)

    user = users(:admin)
    sign_in user
    visit feeds_path

    # Check header authentication state
    assert_selector "header" do
      assert_selector "[data-controller='dropdown']"
      assert_selector ".rounded-full", text: user_initials(user)
      assert_no_link "Sign In"
    end

    # Test dropdown functionality
    find("[data-action='click->dropdown#toggle']").click
    assert_selector "[data-dropdown-target='menu']" do
      assert_link "Sign Out"
      assert_link "Your Profile"
      assert_link "Settings"
    end
  end

  test "sidebar navigation is visible on desktop" do
    # Set desktop viewport size
    page.driver.browser.manage.window.resize_to(1024, 680)

    visit feeds_path

    # Check sidebar is visible and contains navigation links
    assert_selector "[data-sidebar-target='sidebar']" do
      assert_link "Dashboard", href: "/"
      assert_link "Add Content", href: new_content_path
      assert_link "Browse Content", href: contents_path
      assert_link "Feeds", href: feeds_path
      assert_link "Screens", href: screens_path
    end
  end

  test "sidebar navigation shows admin links when authenticated" do
    # Set desktop viewport size
    page.driver.browser.manage.window.resize_to(1024, 680)

    user = users(:admin)
    sign_in user
    visit feeds_path

    # Check admin section is visible in sidebar
    assert_selector "[data-sidebar-target='sidebar']" do
      assert_text "ADMINISTRATION"
      assert_link "Settings", href: admin_settings_path
      assert_link "Templates", href: templates_path
      assert_link "Users"
      assert_link "System"
    end
  end

  test "mobile sidebar toggle functionality" do
    # Set mobile viewport size
    page.driver.browser.manage.window.resize_to(375, 667)

    visit feeds_path

    # Sidebar should be hidden initially on mobile
    sidebar = find("[data-sidebar-target='sidebar']")
    assert sidebar[:class].include?("-translate-x-full")

    # Test sidebar toggle
    find("[data-action='click->sidebar#toggle']").click

    # Sidebar should be visible after toggle
    assert_not sidebar[:class].include?("-translate-x-full")
    assert sidebar[:class].include?("translate-x-0")

    # Overlay should be visible
    overlay = find("[data-sidebar-target='overlay']")
    assert_equal "block", overlay[:style].match(/display:\s*([^;]+)/)[1]
  end

  test "mobile sidebar shows correct authentication state" do
    # Set mobile viewport size
    page.driver.browser.manage.window.resize_to(375, 667)

    # Test unauthenticated state
    visit feeds_path
    find("[data-action='click->sidebar#toggle']").click

    within "[data-sidebar-target='sidebar']" do
      assert_no_text "Administration"
    end

    # Test authenticated state
    user = users(:admin)
    sign_in user
    visit feeds_path

    find("[data-action='click->sidebar#toggle']").click
    within "[data-sidebar-target='sidebar']" do
      assert_text "ADMINISTRATION"
      assert_link "Settings", href: admin_settings_path
    end
  end

  test "header shows page title on desktop" do
    # Set desktop viewport size
    page.driver.browser.manage.window.resize_to(1024, 680)

    visit feeds_path

    # Check that header shows page title on desktop
    assert_selector "header h1", text: "Feeds"
  end

  test "header shows mobile menu button and logo on mobile" do
    # Set mobile viewport size
    page.driver.browser.manage.window.resize_to(375, 667)

    visit feeds_path

    # Check mobile header elements
    assert_selector "header" do
      assert_selector "[data-action='click->sidebar#toggle']"
      assert_selector "img[alt='Concerto']"
      assert_text "Concerto"
    end
  end

  private

  def user_initials(user)
    if user.first_name.present? && user.last_name.present?
      (user.first_name[0] + user.last_name[0]).upcase
    else
      user.email[0].upcase
    end
  end
end
