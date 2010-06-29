require 'test_helper'

class ContentTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "content attributes must not be empty" do
    content = Content.new
    assert content.invalid?
    assert content.errors[:name].any?
    assert content.errors[:kind].any?
    assert content.errors[:duration].any?
    assert content.errors[:user].any?
  end

  # Content must be associated with a system kind
  test "kind cannot unassociated" do
    content = Content.new(:name => "Sample Ticker",
                          :user => users(:katie),
                          :duration => 10)
    assert content.invalid?, "Content kind is blank"
    content.kind_id = 0
    assert content.invalid?, "Content kind is unassociated"
    content.kind = kinds(:ticker)
    assert content.valid?, "Content kind is associated with ticker"
  end
  
  # Content must be associated with a user
  test "user cannot unassociated" do
    content = Content.new(:name => "Sample Ticker",
                          :kind_id => kinds(:ticker).id,
                          :duration => 10)
    assert content.invalid?, "Content user is blank"
    content.user_id = 0
    assert content.invalid?, "Content user is unassociated"
    content.user = users(:katie)
    assert content.valid?, "Content user is Katie"
  end

  # is_active? should determine if the content is considered
  # active or not.  This test uses a k-map style definition
  # where the end_date belongs up top of the grid and start_date
  # belongs on the side.
  test "is active functions correctly" do
    dates = [nil, 1.day.ago, 1.day.from_now]
    expected_results = [[true,false,true],
                        [true,false,true],
                        [false,false,false]]
    
    dates.each_with_index do |start_time, row|
      dates.each_with_index do |end_time, col|
        content = Content.new(:start_time => start_time,
                               :end_time => end_time)
        assert_equal content.is_active?, expected_results[row][col]
      end
    end
  end
end
