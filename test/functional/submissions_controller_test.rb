require 'test_helper'

class SubmissionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "show redirects to correct feed" do
    get :show, :feed_id => feeds(:boring_announcements).id, :id => submissions(:approved_ticker).id
    assert_redirected_to feed_submissions_path(feeds(:boring_announcements))
  end

  test "show feed does not have moderation" do
    get :index, :feed_id => feeds(:service).id
    assert_select ".dd-moderate", 0
    assert_select "button", 0
  end

  test "show feed does not show denied" do
    @feed = feeds(:service)
    get :index, :feed_id => @feed.id
    assert_select "a[href=?]", feed_submissions_path(@feed, :state => 'denied'), 0
  end

  test "admin can see denied" do
    sign_in users(:katie)
    @feed = feeds(:service)
    get :index, :feed_id => @feed.id
    assert_select "a[href=?]", feed_submissions_path(@feed, :state => 'denied'), 1
  end

  test "user can not show feed submissions when having no feed access"  do
    sign_in users(:karen)
    @feed = feeds(:secret_announcements)
    get :index, :feed_id => @feed.id
    assert_redirected_to root_path
  end
end
