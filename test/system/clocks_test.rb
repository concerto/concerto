require "application_system_test_case"

class ClocksTest < ApplicationSystemTestCase
  setup do
    @clock = clocks(:time_12h)
    @user = users(:admin)
  end

  test "should create clock with preset format" do
    sign_in @user

    visit new_clock_url

    fill_in "Name", with: "Test Clock"
    fill_in "Duration", with: 10
    choose "clock_format_time_12h"
    @clock.feeds.each do |f|
      check f.name
    end
    click_on "Save Clock"

    assert_text "Clock was successfully created"
  end

  test "should create clock with custom format" do
    sign_in @user

    visit new_clock_url

    fill_in "Name", with: "Custom Clock"
    fill_in "Duration", with: 15
    choose "clock_format_custom"
    fill_in "clock_custom_format_input", with: "h:mm:ss a"
    @clock.feeds.each do |f|
      check f.name
    end
    click_on "Save Clock"

    assert_text "Clock was successfully created"

    # Verify the custom format was saved by checking the edit form
    click_on "Edit this clock"
    assert find_field("clock_format_custom").checked?
    assert_equal "h:mm:ss a", find_field("clock_custom_format_input").value
  end

  test "should edit clock with custom format and preserve format string" do
    # Create a clock with a custom format first
    custom_clock = Clock.create!(
      name: "Custom Format Clock",
      duration: 20,
      user: @user,
      format: "h:mm:ss a EEE" # Custom format not in presets
    )

    sign_in @user

    visit edit_clock_url(custom_clock)

    # The custom radio button should be checked
    assert find_field("clock_format_custom").checked?

    # The custom format text field should contain the format string
    assert_equal "h:mm:ss a EEE", find_field("clock_custom_format_input").value

    # Update the name to verify form works
    fill_in "Name", with: "Updated Custom Clock"
    click_on "Save Clock"

    assert_text "Clock was successfully updated"
    assert_text "Updated Custom Clock"

    # Verify the custom format is still present
    click_on "Edit this clock"
    assert find_field("clock_format_custom").checked?
    assert_equal "h:mm:ss a EEE", find_field("clock_custom_format_input").value
  end

  test "should switch from custom to preset format" do
    # Create a clock with a custom format
    custom_clock = Clock.create!(
      name: "Will Switch Clock",
      duration: 20,
      user: @user,
      format: "h:mm:ss a"
    )

    sign_in @user

    visit edit_clock_url(custom_clock)

    # Custom should be selected initially
    assert find_field("clock_format_custom").checked?

    # Switch to a preset
    choose "clock_format_time_12h"

    # The custom input should be disabled
    assert find_field("clock_custom_format_input").disabled?

    click_on "Save Clock"

    assert_text "Clock was successfully updated"

    # Verify the preset format was saved
    custom_clock.reload
    assert_equal "h:mm a", custom_clock.format
  end

  test "should destroy Clock" do
    sign_in @user

    visit clock_url(@clock)
    accept_confirm do
      click_on "Delete this clock", match: :first
    end

    assert_text "Clock was successfully deleted"
  end
end
