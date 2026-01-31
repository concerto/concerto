require "test_helper"

class RemoteFeedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @remote_feed = remote_feeds(:test_remote_feed)
    @system_admin = users(:system_admin)

    stub_request(:get, /example\.com\/concerto\/contents/)
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
  end

  test "should get new with group admin" do
    sign_in users(:admin)
    get new_remote_feed_url
    assert_response :success
  end

  test "should create remote_feed with group admin" do
    sign_in users(:admin)
    assert_difference("RemoteFeed.count") do
      post remote_feeds_url, params: { remote_feed: { description: @remote_feed.description, name: @remote_feed.name,
        url: @remote_feed.url, group_id: groups(:feed_one_owners).id } }
    end

    assert_redirected_to remote_feed_url(RemoteFeed.last)
  end

  test "should show remote_feed" do
    get remote_feed_url(@remote_feed)
    assert_response :success
  end

  test "should get edit with system admin" do
    sign_in @system_admin
    get edit_remote_feed_url(@remote_feed)
    assert_response :success
  end

  test "should update remote_feed with system admin" do
    sign_in @system_admin
    patch remote_feed_url(@remote_feed), params: { remote_feed: { description: @remote_feed.description, name: @remote_feed.name,
      url: @remote_feed.url } }
    assert_redirected_to remote_feed_url(@remote_feed)
  end

  test "should destroy remote_feed with system admin" do
    sign_in @system_admin
    assert_difference("RemoteFeed.count", -1) do
      delete remote_feed_url(@remote_feed)
    end

    assert_redirected_to feeds_url
  end

  # Authorization tests
  test "should allow group admin to create remote_feed" do
    sign_in users(:admin)
    assert_difference("RemoteFeed.count") do
      post remote_feeds_url, params: { remote_feed: { description: "Remote Test Feed", name: "Test Remote Feed",
        url: "https://example.com/feed", group_id: groups(:moderators).id } }
    end
    assert_redirected_to remote_feed_url(RemoteFeed.last)
  end

  test "should not allow non-group-admin to create remote_feed" do
    sign_in users(:non_member)
    assert_no_difference("RemoteFeed.count") do
      post remote_feeds_url, params: { remote_feed: { description: "Remote Test Feed", name: "Test Remote Feed",
        url: "https://example.com/feed" } }
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow system admin to update remote_feed" do
    sign_in @system_admin
    patch remote_feed_url(@remote_feed), params: { remote_feed: { name: "Updated by system admin" } }
    assert_redirected_to remote_feed_url(@remote_feed)
    @remote_feed.reload
    assert_equal "Updated by system admin", @remote_feed.name
  end

  test "should allow group admin to update remote_feed" do
    sign_in users(:admin)
    patch remote_feed_url(@remote_feed), params: { remote_feed: { name: "Updated by group admin" } }
    assert_redirected_to remote_feed_url(@remote_feed)
    @remote_feed.reload
    assert_equal "Updated by group admin", @remote_feed.name
  end

  test "should allow group member to update remote_feed" do
    sign_in users(:regular)
    patch remote_feed_url(@remote_feed), params: { remote_feed: { name: "Updated by group member" } }
    assert_redirected_to remote_feed_url(@remote_feed)
    @remote_feed.reload
    assert_equal "Updated by group member", @remote_feed.name
  end

  test "should not allow non-group member to update remote_feed" do
    sign_in users(:non_member)
    patch remote_feed_url(@remote_feed), params: { remote_feed: { name: "Unauthorized update" } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @remote_feed.reload
    assert_not_equal "Unauthorized update", @remote_feed.name
  end

  test "should allow system admin to destroy remote_feed" do
    sign_in @system_admin
    assert_difference("RemoteFeed.count", -1) do
      delete remote_feed_url(@remote_feed)
    end
    assert_redirected_to feeds_url
  end

  test "should allow group admin to destroy remote_feed" do
    sign_in users(:admin)
    assert_difference("RemoteFeed.count", -1) do
      delete remote_feed_url(@remote_feed)
    end
    assert_redirected_to feeds_url
  end

  test "should not allow group member to destroy remote_feed" do
    sign_in users(:regular)
    assert_no_difference("RemoteFeed.count") do
      delete remote_feed_url(@remote_feed)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow non-group member to destroy remote_feed" do
    sign_in users(:non_member)
    assert_no_difference("RemoteFeed.count") do
      delete remote_feed_url(@remote_feed)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow system admin to refresh remote_feed" do
    sign_in @system_admin
    assert_nothing_raised do
      get refresh_remote_feed_url(@remote_feed)
    end
    assert_redirected_to remote_feed_url(@remote_feed)
  end

  test "should allow group member to refresh remote_feed" do
    sign_in users(:regular)
    assert_nothing_raised do
      get refresh_remote_feed_url(@remote_feed)
    end
    assert_redirected_to remote_feed_url(@remote_feed)
  end

  test "should not allow non-group member to refresh remote_feed" do
    sign_in users(:non_member)
    get refresh_remote_feed_url(@remote_feed)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  # URL visibility tests
  test "should show URL to system admin" do
    sign_in @system_admin
    get remote_feed_url(@remote_feed)
    assert_response :success
    assert_select "code", text: @remote_feed.url
  end

  test "should show URL to group admin" do
    sign_in users(:admin)
    get remote_feed_url(@remote_feed)
    assert_response :success
    assert_select "code", text: @remote_feed.url
  end

  test "should show URL to group member" do
    sign_in users(:regular)
    get remote_feed_url(@remote_feed)
    assert_response :success
    assert_select "code", text: @remote_feed.url
  end

  test "should not show URL to non-member" do
    sign_in users(:non_member)
    get remote_feed_url(@remote_feed)
    assert_response :success
    assert_select "code", text: @remote_feed.url, count: 0
    assert_select "code", text: "••••••••••••••••"
  end

  test "should not show URL to anonymous user" do
    get remote_feed_url(@remote_feed)
    assert_response :success
    assert_select "code", text: @remote_feed.url, count: 0
    assert_select "code", text: "••••••••••••••••"
  end

  # JSON API URL visibility tests
  test "should include config in JSON for system admin" do
    sign_in @system_admin
    get remote_feed_url(@remote_feed, format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["config"]
    assert_equal @remote_feed.url, json["config"]["url"]
  end

  test "should include config in JSON for group admin" do
    sign_in users(:admin)
    get remote_feed_url(@remote_feed, format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["config"]
    assert_equal @remote_feed.url, json["config"]["url"]
  end

  test "should include config in JSON for group member" do
    sign_in users(:regular)
    get remote_feed_url(@remote_feed, format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json["config"]
    assert_equal @remote_feed.url, json["config"]["url"]
  end

  test "should not include config in JSON for non-member" do
    sign_in users(:non_member)
    get remote_feed_url(@remote_feed, format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_nil json["config"]
  end

  test "should not include config in JSON for anonymous user" do
    get remote_feed_url(@remote_feed, format: :json)
    assert_response :success
    json = JSON.parse(response.body)
    assert_nil json["config"]
  end
end
