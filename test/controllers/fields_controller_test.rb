require "test_helper"

class FieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @field = fields(:main) # referenced by fixtures, so "in use"
    @regular_user = users(:regular)
    @group_admin = users(:admin)
    @system_admin = users(:system_admin)
  end

  # Authentication / authorization

  test "unauthenticated users cannot access fields index" do
    get fields_url
    assert_redirected_to new_user_session_path
  end

  test "signed in users can view fields index" do
    sign_in @regular_user
    get fields_url
    assert_response :success
    assert_select "h1", "Fields"
  end

  test "non-system admins cannot get new" do
    sign_in @group_admin
    get new_field_url
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "system admins can get new" do
    sign_in @system_admin
    get new_field_url
    assert_response :success
    assert_select "h1", "New Field"
  end

  test "non-system admins cannot create fields" do
    sign_in @group_admin
    assert_no_difference("Field.count") do
      post fields_url, params: { field: { name: "Sneaky" } }
    end
    assert_redirected_to root_path
  end

  # Create

  test "system admins can create a field" do
    sign_in @system_admin
    assert_difference("Field.count") do
      post fields_url, params: { field: { name: "Secondary Graphic", alt_names: "Graphic2, Extra" } }
    end
    field = Field.find_by(name: "Secondary Graphic")
    assert_equal [ "Graphic2", "Extra" ], field.alt_names
    assert_redirected_to fields_url
    follow_redirect!
    assert_select ".alert-success", /Field was successfully created/
  end

  test "should not create field with blank name" do
    sign_in @system_admin
    assert_no_difference("Field.count") do
      post fields_url, params: { field: { name: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "should not create field with duplicate name" do
    sign_in @system_admin
    assert_no_difference("Field.count") do
      post fields_url, params: { field: { name: "main" } }
    end
    assert_response :unprocessable_entity
  end

  # Update

  test "system admins can update a field" do
    sign_in @system_admin
    patch field_url(@field), params: { field: { name: "Main Stage" } }
    assert_redirected_to fields_url
    assert_equal "Main Stage", @field.reload.name
  end

  test "non-system admins cannot update a field" do
    sign_in @group_admin
    original = @field.name
    patch field_url(@field), params: { field: { name: "Hacked" } }
    assert_redirected_to root_path
    assert_equal original, @field.reload.name
  end

  # Destroy

  test "system admins can destroy an unused field" do
    sign_in @system_admin
    unused = Field.create!(name: "Unused Field")
    assert_difference("Field.count", -1) do
      delete field_url(unused)
    end
    assert_redirected_to fields_url
    follow_redirect!
    assert_select ".alert-success", /Field was successfully deleted/
  end

  test "cannot destroy a field that is in use" do
    sign_in @system_admin
    assert_no_difference("Field.count") do
      delete field_url(@field)
    end
    assert_redirected_to fields_url
  end

  test "non-system admins cannot destroy a field" do
    sign_in @group_admin
    unused = Field.create!(name: "Unused Field")
    assert_no_difference("Field.count") do
      delete field_url(unused)
    end
    assert_redirected_to root_path
  end
end
