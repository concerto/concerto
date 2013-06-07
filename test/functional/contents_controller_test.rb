require 'test_helper'

class ContentsControllerTest < ActionController::TestCase
  include Devise::TestHelpers
  include ActionDispatch::TestProcess

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "must sign in before new" do
    get :new
    assert_login_failure
  end
  
  #TODO: Test content creation

  test "render full content preview" do
    c = contents(:sample_image)
    sign_in users(:admin)
    get :display, :id => c.id

    file = assigns(:file)
    require 'concerto_image_magick'
    image = ConcertoImageMagick.load_image(file.file_contents)
    assert_equal 750, image.rows
    assert_equal 1000, image.columns
  end
  
  test "render resized content preview" do
    c = contents(:sample_image)
    sign_in users(:admin)
    
    get :display, :id => c.id, :width => "150", :height => "200"

    file = assigns(:file)
    require 'concerto_image_magick'
    image = ConcertoImageMagick.load_image(file.file_contents)    
    assert_equal 150, image.rows
    assert_equal 200, image.columns
    
    get :display, :id => c.id, :height => "200"
    
    file = assigns(:file)
    image = ConcertoImageMagick.load_image(file.file_contents)    
    assert_equal 150, image.rows
    assert_equal 200, image.columns
    
    get :display, :id => c.id, :width => "150"
    
    file = assigns(:file)
    image = ConcertoImageMagick.load_image(file.file_contents)    
    assert_equal 150, image.rows
    assert_equal 200, image.columns
    
    get :display, :id => c.id, :width => "75", :height => "100"

    file = assigns(:file)
    require 'concerto_image_magick'
    image = ConcertoImageMagick.load_image(file.file_contents)    
    assert_equal 75, image.rows
    assert_equal 100, image.columns
  end

  test "render cropped content preview" do
    c = contents(:sample_image)
    sign_in users(:admin)
    get :display, :id => c.id, :crop => "true", :width => "200", :height => "200"

    file = assigns(:file)
    require 'concerto_image_magick'
    image = ConcertoImageMagick.load_image(file.file_contents)
    assert_equal 200, image.rows
    assert_equal 200, image.columns
  end

end
