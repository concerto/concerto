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

  test "nonmoderators cannot reorder feed items" do
    sign_in users(:karen)
    @feed = feeds(:service)
    @submission1 = submissions(:active_approved_ticker)
    @submission2 = submissions(:approved_image)
    get :reorder, feed_id: @feed.id, id: @submission1.id, before: @submission2.id
    assert_response 403, "nonmoderators cannot reorder feed items"
  end

  test "moderators can reorder feed items" do
    sign_in users(:katie)
    @feed = feeds(:service)
    @submission1 = submissions(:active_approved_ticker)
    @submission2 = submissions(:approved_image)
    get :reorder, feed_id: @feed.id, id: @submission1.id, before: @submission2.id
    assert_response 200, "moderators can reorder feed items"
    assert Submission.find(@submission1.id).seq_no < Submission.find(@submission2.id).seq_no, "items were reordered"
  end

  test "reordered items must be on same feed" do
    sign_in users(:katie)
    @feed = feeds(:service)
    @submission1 = submissions(:active_approved_ticker)
    @submission2 = submissions(:active_approved_ticker2)
    get :reorder, feed_id: @feed.id, id: @submission1.id, before: @submission2.id
    assert_response 400
  end

  test "reordered items must be approved" do
    sign_in users(:katie)
    @feed = feeds(:service)
    @submission1 = submissions(:active_approved_ticker)
    @submission2 = submissions(:pending_ticker)
    get :reorder, feed_id: @feed.id, id: @submission1.id, before: @submission2.id
    assert_response 400
  end

  test "reordered items must be active" do
    sign_in users(:katie)
    @feed = feeds(:service)
    @submission1 = submissions(:active_approved_ticker)
    @submission2 = submissions(:approved_ticker)
    get :reorder, feed_id: @feed.id, id: @submission1.id, before: @submission2.id
    assert_response 400
  end

  test "children of reordered submissions have same seqno as parent" do
    sign_in users(:katie)
    @feed = feeds(:boring_announcements)
    @parent1 = submissions(:boring_approved_parent)
    @submission2 = submissions(:boring_approved_image)
    @child1 = submissions(:boring_approved_child)
    get :reorder, feed_id: @feed.id, id: @parent1.id, before: @submission2.id
    assert_response 200
    assert Submission.find(@parent1.id).seq_no == Submission.find(@child1.id).seq_no, "child seqno should match parent"
  end

end
