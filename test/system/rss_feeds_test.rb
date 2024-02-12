require "application_system_test_case"

class RssFeedsTest < ApplicationSystemTestCase
  setup do
    @rss_feed = rss_feeds(:yahoo_rssfeed)
  end

  test "visiting the index" do
    visit rss_feeds_url
    assert_selector "h1", text: "Rss feeds"
  end

  test "should create rss feed" do
    visit rss_feeds_url
    click_on "New rss feed"

    fill_in "Description", with: @rss_feed.description
    fill_in "Name", with: @rss_feed.name
    fill_in "Url", with: @rss_feed.url
    click_on "Create Rss feed"

    assert_text "Rss feed was successfully created"
    click_on "Back"
  end

  test "should update Rss feed" do
    visit rss_feed_url(@rss_feed)
    click_on "Edit this rss feed", match: :first

    fill_in "Description", with: @rss_feed.description
    fill_in "Name", with: @rss_feed.name
    fill_in "Url", with: @rss_feed.url
    click_on "Update Rss feed"

    assert_text "Rss feed was successfully updated"
    click_on "Back"
  end

  test "should destroy Rss feed" do
    visit rss_feed_url(@rss_feed)
    click_on "Destroy this rss feed", match: :first

    assert_text "Rss feed was successfully destroyed"
  end
end
