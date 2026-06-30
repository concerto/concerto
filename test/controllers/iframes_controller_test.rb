require "test_helper"

class IframesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @iframe = iframes(:iframe_example)
    @user = users(:admin)
  end

  test "should show iframe when not logged in" do
    get iframe_url(@iframe)
    assert_response :success
  end

  test "should redirect new when not logged in" do
    get new_iframe_url
    assert_redirected_to new_user_session_url
  end

  test "should get new when logged in" do
    sign_in @user
    get new_iframe_url
    assert_response :success
  end

  test "should redirect create when not logged in" do
    assert_no_difference("Iframe.count") do
      post iframes_url, params: { iframe: {
        duration: @iframe.duration, end_time: @iframe.end_time,
        name: @iframe.name, start_time: @iframe.start_time,
        url: @iframe.url
      } }
    end
    assert_redirected_to new_user_session_url
  end

  test "should create iframe when logged in" do
    sign_in @user
    assert_difference("Iframe.count") do
      post iframes_url, params: { iframe: {
        duration: @iframe.duration, end_time: @iframe.end_time,
        name: @iframe.name, start_time: @iframe.start_time,
        url: "https://dashboard.example.com"
      } }
    end
    assert_redirected_to iframe_url(Iframe.last)
    assert_equal "https://dashboard.example.com", Iframe.last.url
  end

  test "should reject invalid url on create" do
    sign_in @user
    assert_no_difference("Iframe.count") do
      post iframes_url, params: { iframe: {
        duration: @iframe.duration, name: @iframe.name,
        url: "javascript:alert(1)"
      } }
    end
    assert_response :unprocessable_entity
  end

  test "should redirect edit when not logged in" do
    get edit_iframe_url(@iframe)
    assert_redirected_to new_user_session_url
  end

  test "should get edit when logged in" do
    sign_in @user
    get edit_iframe_url(@iframe)
    assert_response :success
  end

  test "should redirect update when not logged in" do
    patch iframe_url(@iframe), params: { iframe: { url: @iframe.url } }
    assert_redirected_to new_user_session_url
  end

  test "should update iframe when logged in" do
    sign_in @user
    patch iframe_url(@iframe), params: { iframe: { url: "https://updated.example.com" } }
    assert_redirected_to iframe_url(@iframe)
    assert_equal "https://updated.example.com", @iframe.reload.url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference("Iframe.count") do
      delete iframe_url(@iframe)
    end
    assert_redirected_to new_user_session_url
  end

  test "should destroy iframe when logged in" do
    sign_in @user
    assert_difference("Iframe.count", -1) do
      delete iframe_url(@iframe)
    end
    assert_redirected_to contents_url
  end

  # Authorization tests
  test "should not allow non-owner to edit iframe" do
    sign_in users(:non_member)
    get edit_iframe_url(@iframe), headers: { "Referer" => iframe_url(@iframe) }
    assert_redirected_to iframe_url(@iframe)
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow non-owner to update iframe" do
    sign_in users(:non_member)
    patch iframe_url(@iframe), params: { iframe: { name: "Unauthorized update" } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @iframe.reload
    assert_not_equal "Unauthorized update", @iframe.name
  end

  test "should not allow non-owner to destroy iframe" do
    sign_in users(:non_member)
    assert_no_difference("Iframe.count") do
      delete iframe_url(@iframe)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
