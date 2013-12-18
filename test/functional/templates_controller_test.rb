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
    assert_redirected_to edit_template_path(actual)
  end
  
  test "importing a simple template" do
    sign_in users(:admin)
    archive = fixture_file_upload("/files/Archive.zip", 'application/zip')
    #Ruby 1.8.7 and lower can't convert Rack::Test::UploadedFile into String
    if RUBY_VERSION > "1.8.7"
      assert_difference('Template.count', 1) do
        put :import, {:template => { :is_hidden => false }, :package => archive}
      end
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
    assert_equal 750, image.rows
    assert_equal 1000, image.columns
  end

  test "render resized (fixed width) template preview" do
    t = templates(:one)
    sign_in users(:admin)
    get :preview, :id => t.id, :format => 'jpg', :width => 100

    image = assigns(:image)
    assert_in_delta  75, image.rows, 1
    assert_equal 100, image.columns
  end

  test "render resized (fixed height) template preview" do
    t = templates(:one)
    sign_in users(:admin)
    get :preview, :id => t.id, :format => 'jpg', :height => 100

    image = assigns(:image)
    assert_in_delta 133, image.columns, 1
    assert_in_delta 100, image.rows, 1
  end

end
