require "application_system_test_case"

class VideosTest < ApplicationSystemTestCase
  setup do
    @video = videos(:video_youtube)
    @user = users(:admin)
  end

  test "visiting the index" do
    visit videos_url
    assert_selector "h1", text: "Videos"
  end

  test "should create video" do
    sign_in @user

    visit videos_url
    click_on "New video"

    fill_in "Duration", with: @video.duration
    fill_in "End time", with: @video.end_time
    fill_in "Name", with: @video.name
    fill_in "Start time", with: @video.start_time
    fill_in "Url", with: @video.url
    click_on "Create Video"

    assert_text "Video was successfully created"
    click_on "Back"
  end

  test "should update Video" do
    sign_in @user

    visit video_url(@video)
    click_on "Edit this video", match: :first

    fill_in "Duration", with: @video.duration
    fill_in "End time", with: @video.end_time.to_s
    fill_in "Name", with: @video.name
    fill_in "Start time", with: @video.start_time.to_s
    fill_in "Url", with: @video.url
    click_on "Update Video"

    assert_text "Video was successfully updated"
    click_on "Back"
  end

  test "should destroy Video" do
    sign_in @user

    visit video_url(@video)
    click_on "Destroy this video", match: :first

    assert_text "Video was successfully destroyed"
  end
end
