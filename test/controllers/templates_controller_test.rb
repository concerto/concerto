require "test_helper"

class TemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @template = templates(:one)
    @system_admin = users(:system_admin)
    @admin_user = users(:admin) # admin of screen_one_owners (has screens)
    @regular_user = users(:regular)
    @non_member = users(:non_member) # not admin of any group with screens
  end

  # Authorization tests
  test "unauthenticated users cannot access templates" do
    get templates_url
    assert_redirected_to new_user_session_path
  end

  test "signed in users can view templates index" do
    sign_in @regular_user
    get templates_url
    assert_response :success
  end

  test "signed in users can view template details" do
    sign_in @regular_user
    get template_url(@template)
    assert_response :success
  end

  test "only group admins with screens can create templates" do
    sign_in @non_member
    get new_template_url
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "group admins with screens can create templates" do
    sign_in @admin_user
    get new_template_url
    assert_response :success
  end

  test "system admins can create templates" do
    sign_in @system_admin
    get new_template_url
    assert_response :success
  end

  test "only system admins can edit templates" do
    sign_in @admin_user
    get edit_template_url(@template)
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "system admins can edit templates" do
    sign_in @system_admin
    get edit_template_url(@template)
    assert_response :success
  end

  test "only system admins can update templates" do
    sign_in @admin_user
    original_name = @template.name
    patch template_url(@template), params: { template: { name: "Hacked Name" } }
    assert_redirected_to root_path
    @template.reload
    assert_equal original_name, @template.name
  end

  test "system admins can update templates" do
    sign_in @system_admin
    patch template_url(@template), params: { template: { name: "Updated Name" } }
    assert_redirected_to template_url(@template)
    @template.reload
    assert_equal "Updated Name", @template.name
  end

  test "only system admins can destroy templates" do
    sign_in @admin_user
    template = templates(:unused)
    assert_no_difference("Template.count") do
      delete template_url(template)
    end
    assert_redirected_to root_path
  end

  test "system admins can destroy templates" do
    sign_in @system_admin
    template = templates(:unused)
    assert_difference("Template.count", -1) do
      delete template_url(template)
    end
    assert_redirected_to templates_url
  end

  # Original functionality tests
  test "should get index" do
    sign_in @admin_user
    get templates_url
    assert_response :success
  end

  test "should get new" do
    sign_in @admin_user
    get new_template_url
    assert_response :success
  end

  test "should create template" do
    sign_in @admin_user
    assert_difference("Template.count") do
      post templates_url, params: { template: { author: @template.author, name: @template.name, positions: @template.positions } }
    end

    assert_redirected_to template_url(Template.last)
  end

  test "should show template" do
    sign_in @admin_user
    get template_url(@template)
    assert_response :success
  end

  test "should get edit" do
    sign_in @system_admin
    get edit_template_url(@template)
    assert_response :success
  end

  test "should update template" do
    sign_in @system_admin
    patch template_url(@template), params: { template: { author: @template.author, name: @template.name, positions: @template.positions } }
    assert_redirected_to template_url(@template)
  end

  test "should destroy template" do
    sign_in @system_admin
    template = templates(:unused)
    assert_difference("Template.count", -1) do
      delete template_url(template)
    end

    assert_redirected_to templates_url
  end
end
