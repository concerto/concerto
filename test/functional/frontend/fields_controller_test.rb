require 'test_helper'

class Frontend::FieldsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :screens, :fields

  test "should get content" do
    get(:contents, {:screen_id => screens(:one).id, :id => fields(:one).id, :format => :json})
    assert_response :success
  end
end
