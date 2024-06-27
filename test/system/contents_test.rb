require "application_system_test_case"

class ContentsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit contents_url
    assert_selector "h1", text: "Contents"
  end

  test "should link to create content" do
    visit contents_url
    click_on "New content"

    assert_selector "h1", text: "Add Content"

    has_link? "New graphic", href: new_graphic_path
    has_link? "New rich text", href: new_rich_text_path
  end
end
