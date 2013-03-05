require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  def setup
    @public_submission = Submission.new({feed: feeds(:service)})
    @hidden_submission = Submission.new({feed: feeds(:secret_announcements)})
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

    s = Submission.new({content: contents(:futuristic_ticker), duration: 10})
    assert !s.valid?, "Submission doesn't have feed"
    s.feed = feeds(:service)
    assert s.valid?, "Submission has feed"
  end

  # Content is critical to a submission
  test "submission requires content" do
    s = Submission.new({feed: feeds(:service), duration: 10})
    assert !s.valid?, "Submission doesn't have content"
    s.content_id = contents(:futuristic_ticker).id
    assert s.valid?, "Submission has content"
  end

  # Test uniqueness of submissions, a piece of content
  # cannot be submitted to the same feed more than once
  test "submissions must be unique" do
    s = Submission.new({content: contents(:old_ticker), feed: feeds(:service), duration: 10})
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

  test "parent propogates moderation" do
    parent = submissions(:pending_parent)
    child = submissions(:pending_child)
    bad_child = submissions(:bad_child)
    distant = submissions(:distant_child)

    assert parent.is_pending?
    parent.moderation_flag = true
    parent.moderator = users(:katie)
    parent.save

    child.reload
    distant.reload
    bad_child.reload

    assert parent.is_approved?
    assert child.is_approved?
    assert_equal submissions(:pending_child).moderator, users(:katie)
    assert submissions(:distant_child).is_denied?
    assert submissions(:bad_child).is_denied?
  end
end
