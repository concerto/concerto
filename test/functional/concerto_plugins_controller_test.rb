require 'test_helper'

class ConcertoPluginsControllerTest < ActionController::TestCase
  setup do
    @concerto_plugin = concerto_plugins(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:concerto_plugins)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create concerto_plugin" do
    assert_difference('ConcertoPlugin.count') do
      post :create, concerto_plugin: { enabled: @concerto_plugin.enabled, gem_name: @concerto_plugin.gem_name, gem_version: @concerto_plugin.gem_version, installed: @concerto_plugin.installed, module_name: @concerto_plugin.module_name, name: @concerto_plugin.name, source: @concerto_plugin.source, source_url: @concerto_plugin.source_url }
    end

    assert_redirected_to concerto_plugin_path(assigns(:concerto_plugin))
  end

  test "should show concerto_plugin" do
    get :show, id: @concerto_plugin
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @concerto_plugin
    assert_response :success
  end

  test "should update concerto_plugin" do
    put :update, id: @concerto_plugin, concerto_plugin: { enabled: @concerto_plugin.enabled, gem_name: @concerto_plugin.gem_name, gem_version: @concerto_plugin.gem_version, installed: @concerto_plugin.installed, module_name: @concerto_plugin.module_name, name: @concerto_plugin.name, source: @concerto_plugin.source, source_url: @concerto_plugin.source_url }
    assert_redirected_to concerto_plugin_path(assigns(:concerto_plugin))
  end

  test "should destroy concerto_plugin" do
    assert_difference('ConcertoPlugin.count', -1) do
      delete :destroy, id: @concerto_plugin
    end

    assert_redirected_to concerto_plugins_path
  end
end
