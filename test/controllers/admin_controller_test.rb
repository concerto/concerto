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
      settings: { oidc_issuer: "Hacked" }
    }
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    refute_equal "Hacked", Setting[:oidc_issuer]
  end

  test "settings index allowed for system admin" do
    sign_in @system_admin
    get admin_settings_path
    assert_response :success
  end

  test "update_settings allowed for system admin" do
    sign_in @system_admin
    patch admin_settings_path, params: {
      settings: { oidc_issuer: "https://updated.example.com" }
    }
    assert_redirected_to admin_settings_path
    assert_equal "https://updated.example.com", Setting[:oidc_issuer]
  end

  test "settings index groups settings by definition group" do
    sign_in @system_admin
    get admin_settings_path
    assert_response :success

    assert_match(/General/, response.body)
    assert_match(/OpenID Connect/, response.body)
    assert_match(/Updates/, response.body)

    assert_select "input[name=?]", "settings[public_registration]"
    assert_select "input[name=?]", "settings[update_prerelease]"
    assert_select "input[name=?]", "settings[oidc_issuer]"
    assert_select "input[name=?]", "settings[oidc_client_id]"
  end

  test "settings index shows labels and descriptions from definitions" do
    sign_in @system_admin
    get admin_settings_path

    assert_match(/Public Registration/, response.body)
    assert_match(/Pre-release Updates/, response.body)
    assert_match(/Allow visitors to create accounts/, response.body)
  end

  test "settings index creates missing settings from definitions" do
    Setting.where(key: "update_prerelease").delete_all
    sign_in @system_admin
    get admin_settings_path
    assert_response :success

    assert_select "input[name=?]", "settings[update_prerelease]"
    assert Setting.exists?(key: "update_prerelease")
  end

  test "updates multiple settings at once" do
    sign_in @system_admin
    patch admin_settings_path, params: {
      settings: {
        oidc_issuer: "https://new-idp.example.com",
        public_registration: "false"
      }
    }

    assert_redirected_to admin_settings_path
    assert_equal "Settings were successfully updated.", flash[:notice]

    assert_equal "https://new-idp.example.com", Setting[:oidc_issuer]
    assert_equal false, Setting[:public_registration]
  end

  test "handles different setting types correctly" do
    sign_in @system_admin
    patch admin_settings_path, params: {
      settings: {
        public_registration: "true",
        update_prerelease: "true",
        oidc_issuer: "https://example.com"
      }
    }

    assert_equal true, Setting[:public_registration]
    assert_equal true, Setting[:update_prerelease]
    assert_equal "https://example.com", Setting[:oidc_issuer]
  end

  test "only permits defined setting keys" do
    sign_in @system_admin
    patch admin_settings_path, params: {
      settings: {
        oidc_issuer: "https://legit.example.com",
        injected_key: "malicious"
      }
    }

    assert_redirected_to admin_settings_path
    assert_equal "https://legit.example.com", Setting[:oidc_issuer]
    assert_nil Setting[:injected_key]
  end
end
