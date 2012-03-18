require 'test_helper'

class ContentsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "should get generic new" do
    get :new
    assert_response :success
  end

  test "should get new graphic" do
    get(:new, {:type => "graphic"})
    assert_response :success
    assert_select(HTML::Selector.new "input[type=file]")
  end

  test "should get new ticker" do
    get(:new, {:type => "ticker"})
    assert_response :success
    assert_select("textarea")
  end

  test "should get index" do
    get :index
    assert_response :success
  end
  
  test "should demoderate submissions on edit" do
    put :update, :id => contents(:sample_ticker).id, :duration => "7"
    related_submissions = contents(:sample_ticker).submissions
    related_submissions.each do |submission|
      assert_nil(submission.moderation_flag)
    end
  end

end
