require 'test_helper'

class Frontend::TemplatesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  fixtures :screens
  fixtures :templates

  test "0x0 template fails gracefully" do
    get(:show, params: { :id => templates(:one).id, :screen_id => screens(:one).id, :width => 0, :height => 0, :format => :png })
    assert_response 400
  end

  test "no size templates are ok" do
    get(:show, params: { :id => templates(:one).id, :screen_id => screens(:one).id, :format => :png })
    assert_response 200
  end
end
