require "application_system_test_case"

class RssFeedsTest < ApplicationSystemTestCase
  setup do
    @rss_feed = rss_feeds(:yahoo_rssfeed)
    @system_admin = users(:system_admin)
  end

  test "should create rss feed" do
    sign_in @system_admin
    visit feeds_url
    click_on "New RSS Feed"

    fill_in "Name", with: @rss_feed.name
    fill_in "Description", with: @rss_feed.description
    fill_in "URL", with: @rss_feed.url
    click_on "Save RSS Feed"

    assert_text "RSS Feed was successfully created"
    click_on "Back"
  end

  test "should update Rss feed" do
    sign_in @system_admin
    visit rss_feed_url(@rss_feed)
    click_on "Edit RSS Feed", match: :first

    fill_in "Name", with: @rss_feed.name
    fill_in "Description", with: @rss_feed.description
    fill_in "URL", with: @rss_feed.url
    click_on "Save RSS Feed"

    assert_text "RSS Feed was successfully updated"
    click_on "Back"
  end

  test "should destroy Rss feed" do
    sign_in @system_admin
    visit rss_feed_url(@rss_feed)
    accept_confirm do
      click_on "Delete this RSS Feed", match: :first
    end

    assert_text "RSS Feed was successfully deleted"
  end
end
