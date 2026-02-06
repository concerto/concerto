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

  test "should get new when signed in" do
    sign_in @admin
    get new_submission_url
    assert_response :success
  end

  test "should create submission" do
    sign_in @admin
    content = rich_texts(:plain_richtext)  # owned by admin
    feed = feeds(:one)
    assert_difference("Submission.count") do
      post submissions_url, params: { submission: { content_id: content.id, feed_id: feed.id } }
    end

    assert_redirected_to submission_url(Submission.last)
  end

  test "should show submission" do
    get submission_url(@submission)
    assert_response :success
  end

  test "should get edit when signed in as system admin" do
    sign_in users(:system_admin)
    get edit_submission_url(@submission)
    assert_response :success
  end

  test "should update submission when signed in as system admin" do
    sign_in users(:system_admin)
    patch submission_url(@submission), params: { submission: { content_id: @submission.content_id, feed_id: @submission.feed_id } }
    assert_redirected_to submission_url(@submission)
  end

  test "should destroy submission" do
    sign_in @admin
    assert_difference("Submission.count", -1) do
      delete submission_url(@submission)
    end

    assert_redirected_to submissions_url
  end

  # Authorization tests
  test "should allow content owner to create submission" do
    sign_in @admin
    content = rich_texts(:plain_richtext)  # owned by admin
    feed = feeds(:one)

    assert_difference("Submission.count") do
      post submissions_url, params: { submission: { content_id: content.id, feed_id: feed.id } }
    end
    assert_redirected_to submission_url(Submission.last)
  end

  test "should not allow non-owner to create submission for others content" do
    sign_in users(:non_member)
    content = rich_texts(:plain_richtext)  # owned by admin
    feed = feeds(:one)

    assert_no_difference("Submission.count") do
      post submissions_url, params: { submission: { content_id: content.id, feed_id: feed.id } }
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow content owner to destroy their submission" do
    sign_in @admin
    submission = submissions(:three)  # content owned by admin

    assert_difference("Submission.count", -1) do
      delete submission_url(submission)
    end
    assert_redirected_to submissions_url
  end

  test "should not allow non-owner to destroy others submission" do
    sign_in users(:non_member)
    submission = submissions(:three)  # content owned by admin

    assert_no_difference("Submission.count") do
      delete submission_url(submission)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
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
