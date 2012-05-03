require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  def setup
    @public_submission = Submission.new({:feed => feeds(:service)})
    @hidden_submission = Submission.new({:feed => feeds(:secret_announcements)})
  end

  # Attributes cannot be left empty/blank
  test "submission attributes must not be empty" do
    submission = Submission.new
    assert submission.invalid?
    assert submission.errors[:duration].any?
    assert submission.errors[:feed].any?
    assert submission.errors[:content].any?
  end

  # Every submission requires a feed
  test "submission requires feed" do
    blank = Submission.new()
    assert !blank.valid?

    s = Submission.new({:content => contents(:futuristic_ticker), :duration => 10})
    assert !s.valid?, "Submission doesn't have feed"
    s.feed = feeds(:service)
    assert s.valid?, "Submission has feed"
  end

  # Content is critical to a submission
  test "submission requires content" do
    s = Submission.new({:feed => feeds(:service), :duration => 10})
    assert !s.valid?, "Submission doesn't have content"
    s.content_id = contents(:futuristic_ticker).id
    assert s.valid?, "Submission has content"
  end

  # Test uniqueness of submissions, a piece of content
  # cannot be submitted to the same feed more than once
  test "submissions must be unique" do
    s = Submission.new({:content => contents(:old_ticker), :feed => feeds(:service), :duration => 10})
    assert !s.valid?, "Submission already exists"
    s.content = contents(:futuristic_ticker)
    assert s.valid?, "Submission doesn't exist"
  end

  # Verify is_approved? is only true for approved content
  test "is_approved?" do
    assert submissions(:approved_ticker).is_approved?
    assert !submissions(:denied_ticker).is_approved?
    assert !submissions(:pending_ticker).is_approved?
  end

  # Verify is_denied? is only true for denied content
  test "is_denied?" do
    assert !submissions(:approved_ticker).is_denied?
    assert submissions(:denied_ticker).is_denied?
    assert !submissions(:pending_ticker).is_denied?
  end

  # Verify is_pending? is only true for pending content
  test "is_pending?" do
    assert !submissions(:approved_ticker).is_pending?
    assert !submissions(:denied_ticker).is_pending?
    assert submissions(:pending_ticker).is_pending?
  end

  # Verify the approve behavior approves the content.
  # If a duration is set, make sure that is used.
  test "submission approval" do
    s = submissions(:pending_ticker)
    assert !s.is_approved?

    assert s.approve(users(:katie), nil), "#{s.errors}"
    assert s.is_approved?
    assert_equal s.moderator, users(:katie)

    assert s.approve(users(:kristen), nil, 123)
    assert s.is_approved?
    assert_equal s.moderator, users(:kristen)
    assert_equal 123, s.duration
  end

  # Make sure content can be denied.
  test "submission denial" do
    s = submissions(:approved_ticker)
    assert !s.is_denied?

    assert s.deny(users(:katie), nil), "#{s.errors}"
    assert s.is_denied?
    assert_equal s.moderator, users(:katie)
  end

  # Make sure content can be unmoderated.  If
  # a duration is used, that one should be used
  # otherwise it should be reset to the
  # content's duration.
  test "submission un-moderation" do
    s = submissions(:denied_ticker)
    assert !s.is_pending?

    assert s.unmoderate(users(:katie), 234), "#{s.errors}"
    assert s.is_pending?
    assert_equal s.moderator, users(:katie)
    assert_equal s.duration, 234

    assert s.unmoderate(users(:katie)), "#{s.errors}"
    assert s.is_pending?
    assert_equal s.moderator, users(:katie)
    assert_equal s.duration, s.content.duration
  end

  # Approved or denied content requires
  # a moderator to be present.
  test "moderated submission needs moderator" do
    s = submissions(:pending_ticker)
    assert s.is_pending?

    assert !s.approve(nil, nil)
    assert !s.is_approved?

    assert s.approve(users(:katie), nil)
    assert s.is_approved?

    s.moderator = nil
    assert s.invalid?

    assert !s.deny(nil, nil)
    assert !s.is_denied?

    assert s.deny(users(:katie), nil)
    assert s.is_denied?

    s.moderator = nil
    assert s.invalid?
  end
end
