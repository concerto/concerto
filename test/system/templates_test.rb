require "application_system_test_case"

class TemplatesTest < ApplicationSystemTestCase
  setup do
    @template = templates(:one)
  end

  test "visiting the index" do
    sign_in users(:regular)
    visit templates_url
    assert_selector "h1", text: "Templates"
  end

  test "should create template" do
    sign_in users(:system_admin)
    visit templates_url
    click_on "New template"

    fill_in "Author", with: @template.author
    fill_in "Name", with: @template.name

    # Upload an image first (required before adding positions)
    attach_file "template[image]", Rails.root.join("test/fixtures/files/template.jpg")

    # Add positions using WYSIWYG editor
    @template.positions.each_with_index do |position, index|
      click_on "+ Add Position"

      # The inspector panel should appear after adding a position
      # Select the field in the inspector (which is shown after adding position)
      if page.has_select?("Field", wait: 2)
        select Field.find(position.field_id).name, from: "Field"
      end

      # Fill in style if present and field is available
      if position.style.present? && page.has_field?("Style (CSS)", wait: 2)
        fill_in "Style (CSS)", with: position.style
      end
    end

    click_on "Save Template"

    assert_text "Template was successfully created"
    click_on "Back"
  end

  test "should update Template" do
    sign_in users(:system_admin)
    visit template_url(@template)
    click_on "Edit this template", match: :first

    fill_in "Author", with: "#{@template.author} Updated"
    fill_in "Name", with: "#{@template.name} Updated"

    # In the WYSIWYG editor, positions are already rendered from the existing template
    # We can verify they exist and optionally modify them
    # For this test, we'll just verify the form can be submitted with existing positions

    click_on "Save Template"

    assert_text "Template was successfully updated"
    click_on "Back"
  end

  test "should destroy Template" do
    sign_in users(:system_admin)
    visit template_url(templates(:unused))
    click_on "Delete this template", match: :first

    assert_text "Template was successfully deleted"
  end
end
