require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  # Every submission requires a feed
  test "submission requires feed" do
    blank = Submission.new()
    assert !blank.valid?
    
    s = Submission.new({:content => contents(:sample_ticker)})
    assert !s.valid?, "Submission doesn't have feed"
    s.feed = feeds(:service)
    assert s.valid?, "Submission has feed"
  end
  
  # Content is critical to a submission
  test "submission requires content" do
    s = Submission.new({:feed => feeds(:service)})
    assert !s.valid?, "Submission doesn't have content"
    s.content_id = contents(:sample_ticker).id
    assert s.valid?, "Submission has content"
  end
  
  # Test uniqueness of submissions, a piece of content
  # cannot be submitted to the same feed more than once
  test "submissions must be unique" do
    s = Submission.new({:content => contents(:old_ticker), :feed => feeds(:service)})
    assert !s.valid?, "Submission already exists"
    s.content = contents(:futuristic_ticker)
    assert s.valid?, "Submission doesn't exist"
  end

end
