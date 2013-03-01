require 'test_helper'

class Frontend::ContentsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  fixtures :screens
  fixtures :fields
  fixtures :contents

  test "should get content for field" do
    get(:index, {screen_id: screens(:one).id, field_id: fields(:one).id, format: :json})
    assert_response :success
    assert_template false

    data = ActiveSupport::JSON.decode(@response.body)
    assert data.length > 0
  end

end
