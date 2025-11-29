require "application_system_test_case"

class ContentsTest < ApplicationSystemTestCase
  test "visiting the index" do
    visit contents_url
    assert_selector "h1", text: "Active Content"

    assert_selector "#contents img", count: (Graphic.active.count + Video.active.count)
    assert_selector "#contents div", text: rich_texts(:e2e_ticker_1).text
  end

  test "viewing expired content" do
    visit contents_url(scope: "expired")
    assert_selector "h1", text: "Expired Content"

    assert_selector "#contents img", count: (Graphic.expired.count + Video.expired.count)
    assert_selector "#contents div", text: rich_texts(:plain_richtext).text
  end

  test "should link to create content" do
    sign_in users(:admin)
    visit contents_url
    click_on "New Content", match: :first

    assert_selector "h1", text: "Add Content"

    has_link? "Add Graphic", href: new_graphic_path
    has_link? "Add Text / HTML", href: new_rich_text_path
    has_link? "Add Video", href: new_video_path
  end
end
