require "application_system_test_case"

class SubmissionsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:admin)
    @pending_submission = submissions(:pending_submission)
  end

  test "visiting the moderation queue" do
    sign_in @admin
    visit submissions_url

    assert_selector "h1", text: "Moderation Queue"
  end

  test "approving a pending submission" do
    sign_in @admin
    visit submissions_url

    assert_text @pending_submission.content.name

    within "form[action='#{moderate_submission_path(@pending_submission)}']", match: :first do
      click_on "Approve"
    end

    assert_text "Submission was approved"
    assert_no_text @pending_submission.content.name # Should disappear from queue
  end

  test "rejecting a pending submission with reason" do
    sign_in @admin
    visit submissions_url

    assert_text @pending_submission.content.name

    click_on "Reject", match: :first
    fill_in "submission_moderation_reason", with: "Inappropriate content"
    click_on "Confirm Reject"

    assert_text "Submission was rejected"
    assert_no_text @pending_submission.content.name # Should disappear from queue
  end

  test "empty moderation queue shows message" do
    sign_in @admin

    # Approve the pending submission first
    @pending_submission.moderate!(status: :approved, moderator: @admin)

    visit submissions_url

    assert_text "All caught up!"
    assert_text "There are no submissions waiting for moderation"
  end
end
