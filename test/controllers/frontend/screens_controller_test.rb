require "test_helper"

class Frontend::ScreensControllerTest < ActionDispatch::IntegrationTest
  def setup
    @screen = screens(:one)
  end

  test "should get show" do
    get frontend_screen_url(id: @screen.id, format: :json)
    assert_response :success

    screen = response.parsed_body
    assert_not_empty screen[:template][:background_uri]
    assert_equal 4, screen[:positions].length
    assert screen[:positions][0].has_key?(:id)
    assert_not_empty screen[:positions][0][:content_uri]
  end

  test "should include config version header" do
    get frontend_screen_url(id: @screen.id, format: :json)
    assert_response :success

    config_version = response.headers["X-Config-Version"]
    assert_not_nil config_version
    assert_equal 32, config_version.length
    assert_match(/^[a-f0-9]{32}$/, config_version)
  end

  test "should handle template without attached image" do
    # Create a screen with a template that has no image attached
    template_without_image = Template.create!(name: "Template Without Image")
    Position.create!(
      template: template_without_image,
      field: fields(:main),
      top: 0.0,
      left: 0.0,
      bottom: 1.0,
      right: 1.0,
      style: "font-family: Arial;"
    )
    screen_without_image = Screen.create!(
      name: "Screen Without Image",
      template: template_without_image,
      group: groups(:screen_one_owners)
    )

    get frontend_screen_url(id: screen_without_image.id, format: :json)
    assert_response :success

    screen = response.parsed_body
    assert_nil screen[:template][:background_uri], "Background URI should be nil when no image is attached"
    assert_equal 1, screen[:positions].length
  end
end
