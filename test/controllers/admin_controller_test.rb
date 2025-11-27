require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    @system_admin = users(:system_admin)
    @regular_user = users(:regular)
  end

  # Authorization tests
  test "settings index requires system admin" do
    sign_in @regular_user
    get admin_settings_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "update_settings requires system admin" do
    sign_in @regular_user
    patch admin_settings_path, params: {
      settings: { site_name: "Hacked" }
    }
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    # Verify the setting was NOT updated
    refute_equal "Hacked", Setting[:site_name]
  end

  test "settings index allowed for system admin" do
    sign_in @system_admin
    get admin_settings_path
    assert_response :success
  end

  test "update_settings allowed for system admin" do
    sign_in @system_admin
    patch admin_settings_path, params: {
      settings: { site_name: "Updated by Admin" }
    }
    assert_redirected_to admin_settings_path
    assert_equal "Updated by Admin", Setting[:site_name]
  end

  # Original functionality tests
  test "settings index groups settings by prefix" do
    sign_in @system_admin
    get admin_settings_path
    assert_response :success

    # Check that the response includes section headings
    assert_match(/Site/, response.body)
    assert_match(/Oidc/, response.body)

    # Check that settings appear under the correct sections
    # Site section should contain site_name field
    assert_select "input[name=?]", "settings[site_name]"

    # OIDC section should contain OIDC-related fields
    assert_select "input[name=?]", "settings[oidc_issuer]"
    assert_select "input[name=?]", "settings[oidc_client_id]"
  end

  test "updates multiple settings at once" do
    sign_in @system_admin
    patch admin_settings_path, params: {
      settings: {
        site_name: "Updated Site",
        oidc_issuer: "https://new-idp.example.com",
        items_per_page: "20"
      }
    }

    assert_redirected_to admin_settings_path
    assert_equal "Settings were successfully updated.", flash[:notice]

    # Verify each setting was updated with correct type
    assert_equal "Updated Site", Setting[:site_name]
    assert_equal "https://new-idp.example.com", Setting[:oidc_issuer]
    assert_equal 20, Setting[:items_per_page]
  end

  test "handles different setting types correctly" do
    sign_in @system_admin
    patch admin_settings_path, params: {
      settings: {
        items_per_page: "15",
        maintenance_mode: "true",
        admin_emails: '["new@example.com"]'
      }
    }

    # Integer type
    assert_equal 15, Setting[:items_per_page]

    # Boolean type
    assert_equal true, Setting[:maintenance_mode]

    # Array type
    assert_equal [ "new@example.com" ], Setting[:admin_emails]
  end
end
