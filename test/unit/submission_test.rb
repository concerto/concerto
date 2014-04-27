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
    assert_equal users(:katie), submissions(:pending_child).moderator
    assert submissions(:distant_child).is_denied?
    assert submissions(:bad_child).is_denied?
  end

  test "submissions to moderate for feed doesn't include dynamic children" do
    subs = feeds(:important_announcements).submissions_to_moderate
    assert subs.include?(submissions(:important_dynamic))
    assert !subs.include?(submissions(:important_dynamic_child))
  end

  test "moderation_text returns expected results" do
    assert_equal "Approved", submissions(:approved_ticker).moderation_text
    assert_equal "Rejected", submissions(:denied_ticker).moderation_text
    assert_equal "Pending", submissions(:pending_ticker).moderation_text
  end

  test "deny expired pending content" do
    assert submissions(:pending_ticker).is_pending?
    assert submissions(:important_dynamic).is_pending?
    assert submissions(:important_dynamic_child).is_pending?

    # expire the content
    c = Content.where(:name => contents(:sample_dynamic_content).name).first
    c.end_time = 2.days.ago
    c.save
    c = Content.where(:name => contents(:dynamic_child_content).name).first
    c.end_time = 2.days.ago
    c.save

    Submission::deny_old_expired
    assert Submission.find(submissions(:pending_ticker).id).is_pending?
    assert Submission.find(submissions(:important_dynamic).id).is_denied?
    assert Submission.find(submissions(:important_dynamic_child).id).is_denied?
  end
end
