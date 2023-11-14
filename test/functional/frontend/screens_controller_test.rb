require 'test_helper'

class Frontend::ScreensControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  fixtures :screens

  test "should get screen frontend" do
    @request.cookies['concerto_screen_token'] = screens(:one).screen_token
    get(:show, {:id => screens(:one).id})
    assert_response :success
  end

  test "private screen frontend is not public" do
    get(:show, {:id => screens(:one).id})
    assert_response 401
  end

  test "private screen setup data is not public" do
    get(:setup, {:id => screens(:one).id, :format => :json})
    assert_response 403
  end

  test "should get screen setup" do
    @request.cookies['concerto_screen_token'] = screens(:one).screen_token
    get(:setup, {:id => screens(:one).id, :format => :json})
    assert_response :success
    assert_not_nil assigns(:screen)
  end

  test "screen setup makes sense" do
    @request.cookies['concerto_screen_token'] = screens(:one).screen_token
    get(:setup, {:id => screens(:one).id, :format => :json})
    data = ActiveSupport::JSON.decode(@response.body)
    assert_equal data['name'], screens(:one).name
    assert_equal data['template']['positions'].length,
                 screens(:one).template.positions.length
    assert data['template']['path'].length > 0
    data['template']['positions'].each do |p|
      assert p['field_contents_path'].length > 0
    end
    assert_equal data['locale'], screens(:one).locale
  end

  test "frontend callback works" do
    screens(:two).class.send(:set_callback, :frontend_display, :before) do
      self.template = Template.where(:is_hidden => true).first
    end
    get(:setup, {:id => screens(:two).id, :format => :json})
    assert_response :success
    assert_not_nil assigns(:screen)
    assert_equal assigns(:screen).template, templates(:hidden)
    screens(:two).class.send(:reset_callbacks, :frontend_display)
  end

  test "cannot setup missing screen" do
    get(:setup, {:id => 'abc', :format => :json})
    assert_response :missing
    assert_equal ActiveSupport::JSON.decode(@response.body), {}
  end

  test "v1 redirects to screen" do
    get(:index, {:mac => 'a1:b2:c3'})
    assert_redirected_to frontend_screen_path(screens(:two))
  end

  test "v1 forbids private screens" do
    get(:index, {:mac => 'deadbeef'})
    assert_response :forbidden
  end

  # Tests the CORS preflight request
  test "frontend allows cross origin requests" do
    authorize_screen_via_basic(screens(:one))
    process(:show_options, "OPTIONS", {:id=>screens(:one).id})
    assert_response :success
    assert_equal "*", @response.headers['Access-Control-Allow-Origin']
    assert_equal "*", @response.headers['Access-Control-Allow-Methods']
    assert_equal "true", @response.headers['Access-Control-Allow-Credentials']
    assert_equal "Authorization", @response.headers['Access-Control-Allow-Headers']
    assert_equal "", @response.body
  end

  # Tests the frontend JS login mechanism
  test "frontend basic auth succeeds" do
    authorize_screen_via_basic(screens(:one))
    get(:show, {:id=>screens(:one).id, :request_cookie=>"1"})
    assert_response :success
    auth_cookie = "concerto_screen_token="+screens(:one).screen_token
    assert @response.headers['Set-Cookie'].include? auth_cookie
  end

  private

  # Log in the screen the same way the player would for a first-time request
  # be sure to call with a screen which has proper credentials
  def authorize_screen_via_basic(screen)
   @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('screen', screen.screen_token)
  end
end
