require "application_system_test_case"

class ContentsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit contents_url
    assert_selector "h1", text: "Contents"
  end

  test "should create content" do
    visit contents_url
    click_on "New content"

    # fill_in "Config", with: @content.config
    # fill_in "Duration", with: @content.duration
    # fill_in "End time", with: @content.end_time
    # fill_in "Name", with: @content.name
    # fill_in "Start time", with: @content.start_time
    # fill_in "Text", with: @content.text
    # fill_in "Type", with: @content.type
    # click_on "Create Content"

    # assert_text "Content was successfully created"
    # click_on "Back"
  end
end
