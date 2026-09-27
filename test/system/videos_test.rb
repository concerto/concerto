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
    fill_in "End Time", with: @video.end_time.strftime("%m%d%Y\t%I%M%P")
    fill_in "Name", with: @video.name
    fill_in "Start Time", with: @video.start_time.strftime("%m%d%Y\t%I%M%P")
    fill_in "Video URL", with: @video.url
    click_on "Save Video"

    assert_text "Video was successfully updated"
    # Typing a raw time string lands keystrokes in the wrong segments and can
    # leave a value the browser refuses to submit, so check what was saved.
    saved = Video.find(@video.id)
    assert_equal @video.start_time, saved.start_time
    assert_equal @video.end_time, saved.end_time
    click_on "Back"
  end

  test "should destroy Video" do
    sign_in @user

    visit video_url(@video)
    accept_confirm do
      click_on "Delete this video", match: :first
    end

    assert_text "Video was successfully deleted"
  end
end
