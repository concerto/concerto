require 'test_helper'

class ContentsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "must sign in before new" do
    get :new
    assert_login_failure
  end

  test "should get generic new" do
    sign_in users(:katie)
    get :new
    assert_response :success
  end
  
  test "should get new graphic" do
    sign_in users(:katie)
    get(:new, {:type => "graphic"})
    assert_response :success
    assert_select(HTML::Selector.new "input[type=file]")
    assert_select "li.active > a", {:text => "Graphic"}
  end

  test "should get new ticker" do
    sign_in users(:katie)
    get(:new, {:type => "ticker"})
    assert_response :success
    assert_select("textarea")
    assert_select "li.active > a", {:text => "Ticker Text"}
  end

  test "should fallback to generic" do
    sign_in users(:katie)
    get(:new, {:type => "bananas"})
    assert_response :success
    assert_select(HTML::Selector.new "input[type=file]")
  end

  test "broken default type raises exception" do
    sign_in users(:katie)
    default = ConcertoConfig.find_by_key("default_upload_type")
    default.delete

    assert_raise RuntimeError do
      get :new
    end
  end

  test "should demoderate submissions on edit" do
    sign_in users(:admin)
    put :update, :id => contents(:sample_ticker).id, :content => { :duration => "7" }
    related_submissions = contents(:sample_ticker).submissions
    related_submissions.each do |submission|
      assert_nil(submission.moderation_flag)
    end
  end

  test "some feeds do not want graphics" do
    sign_in users(:katie)
    get(:new, {:type => "graphic"})
    assert_response :success
    assert_select 'input[type="checkbox"][disabled="disabled"]', 4
  end

end
