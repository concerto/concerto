require "application_system_test_case"

class RichTextsTest < ApplicationSystemTestCase
  setup do
    @rich_text = rich_texts(:plain_richtext)
  end

  test "visiting the index" do
    visit rich_texts_url
    assert_selector "h1", text: "Rich texts"
  end

  test "should create rich text" do
    visit rich_texts_url
    click_on "New rich text"

    fill_in "Duration", with: @rich_text.duration
    fill_in "End time", with: @rich_text.end_time
    fill_in "Name", with: @rich_text.name
    fill_in "Start time", with: @rich_text.start_time
    fill_in "Text", with: @rich_text.text
    select @rich_text.render_as, from: "Type"
    @rich_text.feeds.each do |f|
      check f.name
    end
    click_on "Create Rich text"

    assert_text "Rich text was successfully created"
    click_on "Back"
  end

  test "should update Rich text" do
    visit rich_text_url(@rich_text)
    click_on "Edit this rich text", match: :first

    fill_in "Duration", with: @rich_text.duration
    fill_in "End time", with: @rich_text.end_time.strftime("%m%d%Y\t%I%M%P")
    fill_in "Name", with: @rich_text.name
    fill_in "Start time", with: @rich_text.start_time.strftime("%m%d%Y\t%I%M%P")
    fill_in "Text", with: @rich_text.text
    select @rich_text.render_as, from: "Type"
    @rich_text.feeds.each do |f|
      check f.name
    end
    click_on "Update Rich text"

    assert_text "Rich text was successfully updated"
    click_on "Back"
  end

  test "should destroy Rich text" do
    visit rich_text_url(@rich_text)
    click_on "Destroy this rich text", match: :first

    assert_text "Rich text was successfully destroyed"
  end
end
