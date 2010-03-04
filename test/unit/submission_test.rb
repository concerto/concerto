require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  #Test for required associations
  test "submission requires feed" do
    blank = Submission.new()
    assert !blank.valid?
    
    s = Submission.new({:content => contents(:new)})
    assert !s.valid?, "Submission doesn't have feed"
    s.feed = feeds(:one)
    assert s.valid?, "Submission has feed"
  end
  test "submission requires content" do
    s = Submission.new({:feed => feeds(:one)})
    assert !s.valid?, "Submission doesn't have content"
    s.content_id = contents(:new).id
    assert s.valid?, "Submission has content"
  end
  
  #Test uniqueness of submissions
  test "submissions must be unique" do
    s = Submission.new({:content => contents(:one), :feed => feeds(:one)})
    assert !s.valid?, "Submission already exists"
    s.content = contents(:new)
    assert s.valid?, "Submission doesn't exist"
  end
  
  #Test scoping
  test "approved content" do 
    s = submissions(:one_one)
    approved = Submission.approved.all
    assert s.moderation_flag, "Submission approved"
    assert_equal approved.length, 1, "Only 1 approved"
    assert_equal approved.first, s, "Submission matches approved"
  end
  test "denied content" do 
    s = submissions(:one_two)
    denied = Submission.denied.all
    assert !s.moderation_flag, "Submission denied"
    assert_equal denied.length, 1, "Only 1 denied"
    assert_equal denied.first, s, "Submission matches denied"
  end
  test "pending content" do 
    s = submissions(:old_one)
    pending = Submission.pending.all
    assert s.moderation_flag.nil?, "Submission pending"
    assert_equal pending.length, 1, "Only 1 pending"
    assert_equal pending.first, s, "Submission matches pending"
  end
end
