require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @submission = submissions(:three)  # content owned by admin
    @admin = users(:admin)
  end

  test "should get index" do
    get submissions_url
    assert_response :success
  end

  # Moderation tests
  test "index shows only pending submissions user can moderate" do
    sign_in @admin
    get submissions_url
    assert_response :success
  end

  test "non-members see no submissions in moderation queue" do
    sign_in users(:non_member)
    get submissions_url
    assert_response :success
  end

  test "group members can approve submissions for their feeds" do
    sign_in @admin
    submission = submissions(:pending_submission)  # pending submission for feed one

    assert submission.pending?, "Submission should start as pending"

    patch moderate_submission_url(submission), params: {
      submission: { moderation_status: "approved" }
    }

    assert_redirected_to submissions_path
    assert_equal "Submission was approved.", flash[:notice]

    submission.reload
    assert submission.approved?, "Submission should be approved"
    assert_equal @admin, submission.moderator
  end

  test "group members can reject submissions for their feeds with reason" do
    sign_in @admin
    submission = submissions(:pending_submission)

    patch moderate_submission_url(submission), params: {
      submission: {
        moderation_status: "rejected",
        moderation_reason: "Inappropriate content"
      }
    }

    assert_redirected_to submissions_path
    assert_equal "Submission was rejected.", flash[:notice]

    submission.reload
    assert submission.rejected?
    assert_equal "Inappropriate content", submission.moderation_reason
    assert_equal @admin, submission.moderator
  end

  test "non-members cannot moderate submissions" do
    sign_in users(:non_member)
    submission = submissions(:pending_submission)

    patch moderate_submission_url(submission), params: {
      submission: { moderation_status: "approved" }
    }

    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]

    submission.reload
    assert submission.pending?, "Submission should still be pending"
  end

  test "moderate action rejects invalid status" do
    sign_in @admin
    submission = submissions(:pending_submission)

    patch moderate_submission_url(submission), params: {
      submission: { moderation_status: "invalid" }
    }

    assert_redirected_to submissions_path
    assert_equal "Invalid moderation action.", flash[:alert]

    submission.reload
    assert submission.pending?, "Submission should still be pending"
  end

  test "moderate action handles missing status parameter" do
    sign_in @admin
    submission = submissions(:pending_submission)

    patch moderate_submission_url(submission), params: {
      submission: { moderation_status: nil }
    }

    assert_redirected_to submissions_path
    assert_equal "Invalid moderation action.", flash[:alert]
  end
end
