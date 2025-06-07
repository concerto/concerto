require "application_system_test_case"

class ContentsTest < ApplicationSystemTestCase
  setup do
    @user = users(:admin)
  end

  test "visiting the index" do
    visit contents_url
    assert_selector "h1", text: "All Content"

    assert_selector "#contents img", count: (Graphic.all.count + Video.all.count)
    assert_selector "#contents div", text: rich_texts(:plain_richtext).text
  end

  test "should link to create content" do
    visit contents_url
    click_on "New content"

    assert_selector "h1", text: "Add Content"

    has_link? "Add Graphic", href: new_graphic_path
    has_link? "Add Text / HTML", href: new_rich_text_path
    has_link? "Add Video", href: new_video_path
  end

  test "new content form only shows feeds active for upload" do
    sign_in @user
    visit new_rich_text_path

    # Regular feeds should be shown
    assert_selector "label", text: feeds(:one).name

    # RSS feeds should not be shown
    assert_no_selector "label", text: rss_feeds(:yahoo_rssfeed).name
  end
end
