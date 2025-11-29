require "application_system_test_case"

class SubmissionsTest < ApplicationSystemTestCase
  setup do
    @submission = submissions(:one)
    @admin = users(:admin)
  end

  test "visiting the index" do
    visit submissions_url
    assert_selector "h1", text: "Submissions"
  end

  test "should create submission" do
    sign_in @admin
    visit submissions_url
    click_on "New submission"

    fill_in "Content", with: @submission.content_id
    fill_in "Feed", with: @submission.feed_id
    click_on "Create Submission"

    assert_text "Submission was successfully created"
    click_on "Back"
  end

  test "should update Submission" do
    sign_in users(:system_admin)
    visit submission_url(@submission)
    click_on "Edit this submission", match: :first

    fill_in "Content", with: @submission.content_id
    fill_in "Feed", with: @submission.feed_id
    click_on "Update Submission"

    assert_text "Submission was successfully updated"
    click_on "Back"
  end

  test "should destroy Submission" do
    sign_in @admin
    visit submission_url(@submission)
    click_on "Remove this submission", match: :first

    assert_text "Submission was successfully removed"
  end
end
