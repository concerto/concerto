require 'test_helper'

class Frontend::TemplatesControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :screens
  fixtures :templates

  test "0x0 template fails gracefully" do
    get(:show, {:id => templates(:one).id, :screen_id => screens(:one).id, :width => 0, :height => 0})
    assert_response 400
  end
end
