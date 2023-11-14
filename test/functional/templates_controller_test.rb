require 'test_helper'

class TemplatesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
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
    #Ruby 1.8.7 and lower can't convert Rack::Test::UploadedFile into String
    if RUBY_VERSION > "1.8.7"
	    sign_in users(:admin)
	    archive = fixture_file_upload("/files/Archive.zip", 'application/zip')    
	    assert_difference('Template.count', 1) do
	      put :import, {:template => { :is_hidden => false }, :package => archive}
	    end
	    actual = assigns(:template).positions.first
	    assert_small_delta 0.025, actual.left
	    assert_small_delta 0.026, actual.top
	    assert_small_delta 0.592, actual.right
	    assert_small_delta 0.796, actual.bottom
    end
  end

  test "importing a simple template with css" do
    #Ruby 1.8.7 and lower can't convert Rack::Test::UploadedFile into String
    if RUBY_VERSION > "1.8.7"
      sign_in users(:admin)
      archive = fixture_file_upload("/files/ArchiveWithCss.zip", 'application/zip')    
      assert_difference('Template.count', 1) do
        put :import, {:template => { :is_hidden => false }, :package => archive}
      end

      assert_equal 1, assigns(:template).media.where(:key => 'original').length
      assert_equal 1, assigns(:template).media.where(:key => 'css').length

      actual = assigns(:template).positions.first
      assert_small_delta 0.025, actual.left
      assert_small_delta 0.026, actual.top
      assert_small_delta 0.592, actual.right
      assert_small_delta 0.796, actual.bottom
    end
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

  test "edit template page" do
    t = templates(:one)
    sign_in users(:admin)
    get :edit, :id => t.id
    assert_response :success
    assert_equal t, assigns(:template)
  end

  test "update a template's media" do
    t = templates(:one)
    sign_in users(:admin)

    assert_equal 2, t.media.length, "this test template should start with two media entries"
    patch :update, id: t.id, template: { name: t.name, template_css: fixture_file_upload('files/ursa_major.css', 'text/css'),
       template_image: fixture_file_upload('files/ursa_major.jpg', 'image/jpg') }
    assert_redirected_to(controller: 'templates', action: 'show')

    t.reload
    assert_equal 4, t.media.length, "new media not uploaded"

    assert t.media.find_by(key: 'replaced_original', file_name: 'file.jpg'), "original image not marked as replaced"
    assert t.media.find_by(key: 'css', file_name: 'ursa_major.css'), "css media not updated"
    assert t.media.find_by(key: 'original', file_name: 'ursa_major.jpg'), "image media not updated"
  end

  test "should not destroy template with screens" do
    t = templates(:one)
    sign_in users(:admin)

    assert t.screens.length > 0, "this test template is supposed to have screens"
    assert_difference('Template.count', 0) do
      delete :destroy, id: t.id
    end
  end

  test "should destroy template" do
    t = templates(:two)
    sign_in users(:admin)

    assert_difference('Template.count', -1) do
      delete :destroy, id: t.id
    end

    assert_redirected_to templates_path
  end

end
