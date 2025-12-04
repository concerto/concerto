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

  test "should import template from ZIP file" do
    sign_in users(:system_admin)
    visit new_template_url

    # Verify import section is visible
    assert_text "Import Template"
    assert_selector "input#zip-upload[type='file']", visible: :hidden

    # Upload the ZIP file (file input is hidden, so need to specify visible: false)
    attach_file "zip-upload", Rails.root.join("test/fixtures/files/valid_template.zip"), visible: false

    # Wait for import to complete - should see success message
    assert_text "Successfully imported \"Test Template\"", wait: 5

    # Verify form fields were populated
    assert_field "Name", with: "Test Template"
    assert_field "Author", with: "Test Author"

    # Verify the background image was loaded (check that the image element is visible)
    assert_selector "img[data-template-editor-target='image']", visible: true, wait: 2

    # Verify positions were imported (should see them in the positions list)
    # Graphics should map to Main field (via alt_names)
    assert_selector ".position-list-item", text: "Main", wait: 2
    # Ticker should map to Ticker field (exact match)
    assert_selector ".position-list-item", text: "Ticker"

    # Verify we can save the imported template
    click_on "Save Template"
    assert_text "Template was successfully created"

    # Verify the template has the correct data
    template = Template.last
    assert_equal "Test Template", template.name
    assert_equal "Test Author", template.author
    assert_equal 2, template.positions.count
    assert template.image.attached?
  end

  test "should show warning for unmapped fields during import" do
    sign_in users(:system_admin)
    visit new_template_url

    # Upload ZIP with unmapped fields - alert will appear after processing
    attach_file "zip-upload", Rails.root.join("test/fixtures/files/unmapped_fields.zip"), visible: false

    # Wait for and accept the warning alert about unmapped fields
    # The alert appears after the success message is shown
    message = accept_alert(wait: 10)

    # Verify alert mentions unmapped fields
    assert_match /Could not map the following fields/, message

    # Verify positions were still imported despite warning
    assert_selector ".position-list-item", minimum: 1
  end

  test "should show error for invalid ZIP file" do
    sign_in users(:system_admin)
    visit new_template_url

    # Upload ZIP without XML descriptor - should trigger error alert
    message = accept_alert do
      attach_file "zip-upload", Rails.root.join("test/fixtures/files/no_xml.zip"), visible: false
      sleep 1 # Give JavaScript time to process
    end

    # Verify error message mentions no XML file
    assert_match /No XML file found/i, message

    # Form should still be visible (import failed, nothing populated)
    assert_selector "input[name='template[name]']"
    assert_field "Name", with: "" # Should be empty since import failed
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
