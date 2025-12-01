require "application_system_test_case"

class ScreensTest < ApplicationSystemTestCase
  setup do
    @screen = screens(:one)
    sign_in users(:admin)
  end

  test "visiting the index" do
    visit screens_url
    assert_selector "h1", text: "Screens"
  end

  test "should create screen" do
    visit screens_url
    click_on "New Screen"

    fill_in "Name", with: @screen.name
    select @screen.group.name, from: "Managers"
    choose @screen.template.name, allow_label_click: true
    click_on "Save Screen"

    assert_text "Screen was successfully created"
    click_on "Back"
  end

  test "should update Screen" do
    visit screen_url(@screen)
    click_on "Edit Screen", match: :first

    fill_in "Name", with: @screen.name
    select @screen.group.name, from: "Managers"
    choose @screen.template.name, allow_label_click: true
    click_on "Save Screen"

    assert_text "Screen was successfully updated"
    click_on "Back"
  end

  test "should destroy Screen" do
    visit screen_url(@screen)
    accept_confirm do
      click_on "Delete Screen", match: :first
    end

    assert_text "Screen was successfully deleted"
  end
end
