require "application_system_test_case"

class ContentsTest < ApplicationSystemTestCase
  setup do
    @content = contents(:one)
  end

  test "visiting the index" do
    visit contents_url
    assert_selector "h1", text: "Contents"
  end

  # test "should update Content" do
  #   visit content_url(@content)
  #   click_on "Edit this content", match: :first

  #   fill_in "Duration", with: @content.duration
  #   fill_in "End time", with: @content.end_time
  #   fill_in "Name", with: @content.name
  #   fill_in "Start time", with: @content.start_time
  #   fill_in "Subtype", with: @content.subtype_id
  #   fill_in "Subtype type", with: @content.subtype_type
  #   click_on "Update Content"

  #   assert_text "Content was successfully updated"
  #   click_on "Back"
  # end

  test "should destroy Content" do
    visit content_url(@content)
    click_on "Destroy this content", match: :first

    assert_text "Content was successfully destroyed"
  end
end
