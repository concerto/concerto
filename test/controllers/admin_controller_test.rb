require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "settings index groups settings by prefix" do
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
