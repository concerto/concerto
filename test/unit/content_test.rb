require 'test_helper'

class ContentTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "content attributes must not be empty" do
    content = Content.new
    assert content.invalid?
    assert content.errors[:name].any?
    assert content.errors[:mime_type].any?
    assert content.errors[:type].any?
    assert content.errors[:duration].any?
    assert content.errors[:user].any?
  end

  # Content must be associated with a system type
  test "type cannot unassociated" do
    content = Content.new(:name => "Sample Ticker",
                          :mime_type => "text/plain",
                          :user => users(:katie),
                          :duration => 10)
    assert content.invalid?, "Content type is blank"
    content.type_id = 0
    assert content.invalid?, "Content type is unassociated"
    content.type = types(:ticker)
    assert content.valid?, "Content type is associated with ticker"
  end
  
  # Content must be associated with a user
  test "user cannot unassociated" do
    content = Content.new(:name => "Sample Ticker",
                          :mime_type => "text/plain",
                          :type_id => types(:ticker).id,
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
