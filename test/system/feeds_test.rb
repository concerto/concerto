require "application_system_test_case"

class FeedsTest < ApplicationSystemTestCase
  setup do
    @feed = feeds(:one)
  end

  test "visiting the index" do
    visit feeds_url
    assert_selector "h1", text: "Feeds"

    assert_text @feed.name
    assert_text (/#{@feed.content.count} .* content/)
  end

  test "visiting a feed" do
    visit feeds_url
    click_on @feed.name
    assert_selector "h1", text: @feed.name

    @feed.content.each do |c|
      assert_text c.name
    end
  end

  test "should create feed" do
    visit feeds_url
    click_on "New feed"

    fill_in "Description", with: @feed.description
    fill_in "Name", with: @feed.name
    click_on "Create Feed"

    assert_text "Feed was successfully created"
    click_on "Back"
  end

  test "should update Feed" do
    visit feed_url(@feed)
    click_on "Edit this feed", match: :first

    fill_in "Description", with: @feed.description
    fill_in "Name", with: @feed.name
    click_on "Update Feed"

    assert_text "Feed was successfully updated"
    click_on "Back"
  end

  test "should destroy Feed" do
    visit feed_url(@feed)
    click_on "Destroy this feed", match: :first

    assert_text "Feed was successfully destroyed"
  end
end
