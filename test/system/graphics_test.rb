require "application_system_test_case"

class GraphicsTest < ApplicationSystemTestCase
  setup do
    @graphic = graphics(:one)
  end

  test "visiting the index" do
    visit graphics_url
    assert_selector "h1", text: "Graphics"
  end

  test "should create graphic" do
    visit graphics_url
    click_on "New graphic"

    fill_in "Duration", with: @graphic.duration
    fill_in "End time", with: @graphic.end_time
    fill_in "Name", with: @graphic.name
    fill_in "Start time", with: @graphic.start_time
    @graphic.feeds.each do |f|
      check f.name
    end
    click_on "Create Graphic"

    assert_text "Graphic was successfully created"
    click_on "Back"
  end

  test "should update Graphic" do
    visit graphic_url(@graphic)
    click_on "Edit this graphic", match: :first

    fill_in "Duration", with: @graphic.duration
    fill_in "End time", with: @graphic.end_time.strftime("%m%d%Y\t%I%M%P")
    fill_in "Name", with: @graphic.name
    fill_in "Start time", with: @graphic.start_time.strftime("%m%d%Y\t%I%M%P")
    @graphic.feeds.each do |f|
      check f.name
    end
    click_on "Update Graphic"

    assert_text "Graphic was successfully updated"
    click_on "Back"
  end

  test "should destroy Graphic" do
    visit graphic_url(@graphic)
    click_on "Destroy this graphic", match: :first

    assert_text "Graphic was successfully destroyed"
  end
end
