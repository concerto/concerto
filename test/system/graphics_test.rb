require "application_system_test_case"

class GraphicsTest < ApplicationSystemTestCase
  setup do
    @graphic = graphics(:one)
    @user = users(:admin)
  end

  test "should create graphic" do
    sign_in @user

    visit new_graphic_url

    fill_in "Duration", with: @graphic.duration
    fill_in "End Time", with: @graphic.end_time
    fill_in "Name", with: @graphic.name
    fill_in "Start Time", with: @graphic.start_time
    @graphic.feeds.each do |f|
      check f.name
    end
    attach_file "Image", file_fixture("one.jpg")
    click_on "Save Graphic"

    assert_text "Graphic was successfully created"
    click_on "Back"
  end

  test "should update Graphic" do
    sign_in @user

    visit graphic_url(@graphic)
    click_on "Edit this graphic", match: :first

    fill_in "Duration", with: @graphic.duration
    fill_in "End Time", with: @graphic.end_time.strftime("%m%d%Y\t%I%M%P")
    fill_in "Name", with: @graphic.name
    fill_in "Start Time", with: @graphic.start_time.strftime("%m%d%Y\t%I%M%P")
    @graphic.feeds.each do |f|
      check f.name
    end
    click_on "Save Graphic"

    assert_text "Graphic was successfully updated"
    click_on "Back"
  end

  test "should destroy Graphic" do
    sign_in @user

    visit graphic_url(@graphic)
    page.accept_confirm do
      click_on "Destroy this graphic", match: :first
    end

    assert_text "Graphic was successfully destroyed"
  end
end
