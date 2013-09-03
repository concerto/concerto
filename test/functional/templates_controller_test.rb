require 'test_helper'

class TemplatesControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  include ActionDispatch::TestProcess

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "must sign in before new" do
    get :new
    assert_login_failure
  end

  test "should create template" do
    sign_in users(:admin)
    assert_difference('Template.count', 1) do
      post :create, {:template => {:name => "leet template", :author => "the bat", :is_hidden => false}}
    end
    actual = assigns(:template)
    actual.media.each do |media|
      assert_equal("original", media.key)
    end
    assert_redirected_to template_path(actual)
  end
  
  test "importing a simple template" do
    sign_in users(:admin)
    file = fixture_file_upload("/files/simple_template.xml", 'text/xml')
    image = fixture_file_upload("/files/simple_template.xml", 'image')
    assert_difference('Template.count', 1) do
      put :import, {:template => { :is_hidden => false }, :descriptor => file, :image => image}
    end
    actual = assigns(:template).positions.first
    assert_small_delta 0.025, actual.left
    assert_small_delta 0.026, actual.top
    assert_small_delta 0.592, actual.right
    assert_small_delta 0.796, actual.bottom
  end

  test "render full template preview" do
    t = templates(:one)
    sign_in users(:admin)
    get :preview, :id => t.id, :format => 'jpg'

    image = assigns(:image)
    assert_equal image.rows, 750
    assert_equal image.columns, 1000
  end

  test "render resized (fixed width) template preview" do
    t = templates(:one)
    sign_in users(:admin)
    get :preview, :id => t.id, :format => 'jpg', :width => 100

    image = assigns(:image)
    assert_in_delta  image.rows, 75, 1
    assert_equal image.columns, 100
  end

  test "render resized (fixed height) template preview" do
    t = templates(:one)
    sign_in users(:admin)
    get :preview, :id => t.id, :format => 'jpg', :height => 100

    image = assigns(:image)
    assert_in_delta image.columns, 133, 1
    assert_in_delta image.rows, 100, 1
  end

end
