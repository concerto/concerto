require "application_system_test_case"

class VideosTest < ApplicationSystemTestCase
  setup do
    @video = videos(:video_youtube)
    @user = users(:admin)
  end

  test "should create video" do
    sign_in @user

    visit new_video_url

    fill_in "Duration", with: @video.duration
    fill_in "End Time", with: @video.end_time
    fill_in "Name", with: @video.name
    fill_in "Start Time", with: @video.start_time
    fill_in "Video URL", with: @video.url
    click_on "Save Video"

    assert_text "Video was successfully created"
    click_on "Back"
  end

  test "should update Video" do
    sign_in @user

    visit video_url(@video)
    click_on "Edit this video", match: :first

    fill_in "Duration", with: @video.duration
    fill_in "End Time", with: @video.end_time.to_s
    fill_in "Name", with: @video.name
    fill_in "Start Time", with: @video.start_time.to_s
    fill_in "Video URL", with: @video.url
    click_on "Save Video"

    assert_text "Video was successfully updated"
    click_on "Back"
  end

  test "should destroy Video" do
    sign_in @user

    visit video_url(@video)
    page.accept_confirm do
      click_on "Destroy this video", match: :first
    end

    assert_text "Video was successfully destroyed"
  end
end
