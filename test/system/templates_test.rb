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
      page.find('select[id^="template_positions_attributes_"][id$="field_id"]').set(position.field_id)
      page.find('input[id^="template_positions_attributes_"][id$="top"]').set(position.top)
      page.find('input[id^="template_positions_attributes_"][id$="left"]').set(position.left)
      page.find('input[id^="template_positions_attributes_"][id$="bottom"]').set(position.bottom)
      page.find('input[id^="template_positions_attributes_"][id$="right"]').set(position.right)
      page.find('input[id^="template_positions_attributes_"][id$="style"]').set(position.style)
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

    @template.positions.each do |position|
      page.find('select[id^="template_positions_attributes_"][id$="field_id"]').set(position.field_id)
      page.find('input[id^="template_positions_attributes_"][id$="top"]').set(position.top)
      page.find('input[id^="template_positions_attributes_"][id$="left"]').set(position.left)
      page.find('input[id^="template_positions_attributes_"][id$="bottom"]').set(position.bottom)
      page.find('input[id^="template_positions_attributes_"][id$="right"]').set(position.right)
      page.find('input[id^="template_positions_attributes_"][id$="style"]').set(position.style)
    end

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
