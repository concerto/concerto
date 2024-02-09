require "application_system_test_case"

class TextBlobsTest < ApplicationSystemTestCase
  setup do
    @text_blob = text_blobs(:plaintext)
  end

  test "visiting the index" do
    visit text_blobs_url
    assert_selector "h1", text: "Text blobs"
  end

  test "should create text blob" do
    visit text_blobs_url
    click_on "New text blob"

    fill_in "Body", with: @text_blob.body
    select @text_blob.render_as, from: "Render as"
    click_on "Create Text blob"

    assert_text "Text blob was successfully created"
    click_on "Back"
  end

  test "should update Text blob" do
    visit text_blob_url(@text_blob)
    click_on "Edit this text blob", match: :first

    fill_in "Body", with: @text_blob.body
    select @text_blob.render_as, from: "Render as"
    click_on "Update Text blob"

    assert_text "Text blob was successfully updated"
    click_on "Back"
  end

  test "should destroy Text blob" do
    visit text_blob_url(@text_blob)
    click_on "Destroy this text blob", match: :first

    assert_text "Text blob was successfully destroyed"
  end
end
