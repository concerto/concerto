require 'test_helper'

class Frontend::ScreensControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :screens

  test "should get screen frontend" do
    @request.cookies['concerto_screen_token'] = screens(:one).screen_token
    get(:show, {:id => screens(:one).id})
    assert_response :success
    assert_template false
  end

  test "private screen frontend is not public" do
    get(:show, {:id => screens(:one).id})
    assert_response 403
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
end
