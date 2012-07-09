require 'test_helper'

class PluginsControllerTest < ActionController::TestCase
  setup do
    @plugin = plugins(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:plugins)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create plugin" do
    assert_difference('Plugin.count') do
      post :create, plugin: { enabled: @plugin.enabled, gem_name: @plugin.gem_name, gem_version: @plugin.gem_version, installed: @plugin.installed, module_name: @plugin.module_name, name: @plugin.name, source: @plugin.source, source_url: @plugin.source_url }
    end

    assert_redirected_to plugin_path(assigns(:plugin))
  end

  test "should show plugin" do
    get :show, id: @plugin
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @plugin
    assert_response :success
  end

  test "should update plugin" do
    put :update, id: @plugin, plugin: { enabled: @plugin.enabled, gem_name: @plugin.gem_name, gem_version: @plugin.gem_version, installed: @plugin.installed, module_name: @plugin.module_name, name: @plugin.name, source: @plugin.source, source_url: @plugin.source_url }
    assert_redirected_to plugin_path(assigns(:plugin))
  end

  test "should destroy plugin" do
    assert_difference('Plugin.count', -1) do
      delete :destroy, id: @plugin
    end

    assert_redirected_to plugins_path
  end
end
