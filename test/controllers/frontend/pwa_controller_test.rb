require "test_helper"

class Frontend::PwaControllerTest < ActionDispatch::IntegrationTest
  setup do
    @screen = screens(:one)
  end

  test "should show manifest" do
    get frontend_manifest_path(@screen.id, format: :json)
    assert_response :success
    assert_equal "application/json", response.media_type
  end

  test "should return 404 for invalid screen" do
    get frontend_manifest_path(99999, format: :json)
    assert_response :not_found
  end

  test "manifest should include screen id in start_url" do
    get frontend_manifest_path(@screen.id, format: :json)
    json = JSON.parse(response.body)
    assert_includes json["start_url"], @screen.id.to_s
  end

  test "manifest should have required PWA fields" do
    get frontend_manifest_path(@screen.id, format: :json)
    json = JSON.parse(response.body)

    # Verify required PWA manifest fields are present
    assert json.key?("name")
    assert json.key?("short_name")
    assert json.key?("start_url")
    assert json.key?("scope")
    assert json.key?("display")
    assert json.key?("icons")

    # Verify icons structure
    assert json["icons"].is_a?(Array)
    assert json["icons"].length > 0
  end
end
