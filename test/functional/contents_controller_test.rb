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

  test "should upload new ticker" do
    sign_in users(:katie)
    assert_difference('Ticker.count') do
      post :create, :type => 'ticker', :ticker => {:data => "Body", :name => "Ticker Name", :duration => 6,
       :start_time => {:date => "03/25/2013", :time => "12:00am"},
       :end_time => {:date => "04/01/2013", :time => "11:59pm"},
       }, :feed_id => {"0" => feeds(:service).id}
    end
    assert_redirected_to content_path(assigns(:content))
    assert_equal assigns(:content).submissions.length, 1
    assert assigns(:content).submissions.first.moderation_flag

    get(:show, :id => assigns(:content).id)
    assert_select 'p', {:text => "Body"}
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
    default.destroy

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

  test "user cannot submit to all feeds" do
    sign_in users(:kristen)
    get(:new, {:type => "graphic"})
    assert_response :success
    assert_equal assigns(:feeds).length, 4
  end

  test "invalid content id should redirect to browse" do
    sign_in users(:kristen)
    get(:show, :id => 'bogus')
    assert_redirected_to browse_path
  end

  test "missing content should redirect to browse" do
    sign_in users(:kristen)
    get(:show, :id => 99999999)
    assert_redirected_to browse_path
  end
end
