require 'test_helper'

class SubmissionsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def setup
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "show redirects to correct feed" do
    get :show, feed_id: feeds(:boring_announcements).id, id: submissions(:approved_ticker).id
    assert_redirected_to feed_submissions_path(feeds(:boring_announcements))
  end

  test "show feed does not have moderation" do
    get :index, feed_id: feeds(:service).id
    assert_select ".dd-moderate", 0
    assert_select "button", 0
  end

end
