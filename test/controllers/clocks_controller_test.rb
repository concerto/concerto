require "test_helper"

class ClocksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clock = clocks(:time_12h)
    @user = users(:admin)
  end

  test "should show clock when not logged in" do
    get clock_url(@clock)
    assert_response :success
  end

  test "should redirect new when not logged in" do
    get new_clock_url
    assert_redirected_to new_user_session_url
  end

  test "should get new when logged in" do
    sign_in @user
    get new_clock_url
    assert_response :success
  end

  test "should redirect create when not logged in" do
    assert_no_difference("Clock.count") do
      post clocks_url, params: { clock: {
        name: "Test Clock",
        duration: 10,
        format: "h:mm a"
      } }
    end
    assert_redirected_to new_user_session_url
  end

  test "should create clock when logged in" do
    sign_in @user
    assert_difference("Clock.count") do
      post clocks_url, params: { clock: {
        name: "Test Clock",
        duration: 10,
        format: "h:mm a"
      } }
    end
    assert_redirected_to clock_url(Clock.last)
  end

  test "should validate format when creating clock" do
    sign_in @user
    assert_no_difference("Clock.count") do
      post clocks_url, params: { clock: {
        name: "Test Clock",
        duration: 10,
        format: ""
      } }
    end
    assert_response :unprocessable_entity
  end

  test "should redirect edit when not logged in" do
    get edit_clock_url(@clock)
    assert_redirected_to new_user_session_url
  end

  test "should get edit when logged in" do
    sign_in @user
    get edit_clock_url(@clock)
    assert_response :success
  end

  test "should redirect update when not logged in" do
    patch clock_url(@clock), params: { clock: {
      name: "Updated Name",
      format: "EEE, MMM d"
    } }

    assert_redirected_to new_user_session_url
  end

  test "should update clock when logged in" do
    sign_in @user
    patch clock_url(@clock), params: { clock: {
      name: "Updated Clock",
      format: "EEE, MMM d"
    } }
    assert_redirected_to clock_url(@clock)
    @clock.reload
    assert_equal "Updated Clock", @clock.name
    assert_equal "EEE, MMM d", @clock.format
  end

  test "should not update clock with invalid format" do
    sign_in @user
    patch clock_url(@clock), params: { clock: {
      format: ""
    } }
    assert_response :unprocessable_entity
    @clock.reload
    assert_not_equal "", @clock.format
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference("Clock.count") do
      delete clock_url(@clock)
    end
    assert_redirected_to new_user_session_url
  end

  test "should destroy clock when logged in" do
    sign_in @user
    assert_difference("Clock.count", -1) do
      delete clock_url(@clock)
    end
    assert_redirected_to contents_url
  end

  # Authorization tests
  test "should not allow non-owner to edit clock" do
    sign_in users(:non_member)
    get edit_clock_url(@clock), headers: { "Referer" => clock_url(@clock) }
    assert_redirected_to clock_url(@clock)
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow non-owner to update clock" do
    sign_in users(:non_member)
    patch clock_url(@clock), params: { clock: {
      name: "Unauthorized update"
    } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @clock.reload
    assert_not_equal "Unauthorized update", @clock.name
  end

  test "should not allow non-owner to destroy clock" do
    sign_in users(:non_member)
    assert_no_difference("Clock.count") do
      delete clock_url(@clock)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
