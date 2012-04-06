require 'test_helper'

class TemplatesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "should create template" do
    assert_difference('Template.count', 1) do
      post :create, {:template => {:name => "leet template", :author => "the bat", :is_hidden => false}}
    end
    actual = assigns(:template)
    actual.media.each do |media|
      assert_equal("original", media.key)
    end
    assert_redirected_to template_path(actual)
  end

end
