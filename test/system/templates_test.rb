require "application_system_test_case"

class TemplatesTest < ApplicationSystemTestCase
  setup do
    @template = templates(:one)
  end

  test "visiting the index" do
    visit templates_url
    assert_selector "h1", text: "Templates"
  end

  test "should create template" do
    visit templates_url
    click_on "New template"

    fill_in "Author", with: @template.author
    fill_in "Name", with: @template.name

    @template.positions.each do |position|
      click_on "Add Position"
      select position.field, from: "Field"
      fill_in "Top", position.top
      fill_in "Left", position.left
      fill_in "Bottom", position.bottom
      fill_in "Right", position.right
      fill_in "Style", position.style
    end

    click_on "Create Template"

    assert_text "Template was successfully created"
    click_on "Back"
  end

  test "should update Template" do
    visit template_url(@template)
    click_on "Edit this template", match: :first

    fill_in "Author", with: @template.author
    fill_in "Name", with: @template.name
    click_on "Update Template"

    assert_text "Template was successfully updated"
    click_on "Back"
  end

  test "should destroy Template" do
    visit template_url(@template)
    click_on "Destroy this template", match: :first

    assert_text "Template was successfully destroyed"
  end
end
