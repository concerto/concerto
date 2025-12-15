require "application_system_test_case"

class FeedsTest < ApplicationSystemTestCase
  setup do
    @feed = feeds(:one)
    @system_admin = users(:system_admin)
  end

  test "visiting the index" do
    visit feeds_url
    assert_selector "h1", text: "Feeds"

    assert_text @feed.name
    assert_text (/#{@feed.content.count} item/)
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
    sign_in @system_admin
    visit feeds_url
    click_on "New Feed"

    fill_in "Name", with: @feed.name
    fill_in "Description", with: @feed.description
    select @feed.group.name, from: "Managers"
    click_on "Save Feed"

    assert_text "Feed was successfully created"
    click_on "Back"
  end

  test "should update Feed" do
    sign_in @system_admin
    visit feed_url(@feed)
    click_on "Edit Feed", match: :first

    fill_in "Name", with: @feed.name
    fill_in "Description", with: @feed.description
    select @feed.group.name, from: "Managers"
    click_on "Save Feed"

    assert_text "Feed was successfully updated"
    click_on "Back"
  end

  test "should destroy Feed" do
    sign_in @system_admin
    visit feed_url(@feed)
    accept_confirm do
      click_on "Delete this Feed", match: :first
    end

    assert_text "Feed was successfully deleted"
  end
end
