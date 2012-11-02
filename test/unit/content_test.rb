require 'test_helper'

class ContentTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "content attributes must not be empty" do
    content = Content.new
    assert content.invalid?
    assert content.errors[:name].any?
    #assert content.errors[:kind].any?
    assert content.errors[:user].any?
  end

  test "content cannot be it's own parent" do
    content = contents(:sample_ticker)
    content.update_column(:parent_id, content.id)
    assert content.invalid?
    assert content.errors[:parent_id].any?
  end

  # Content must be associated with a system kind.
  # This test is turned off because the associated validation is also disabled.
  # Need to fix.
  #test "kind cannot unassociated" do
  #  content = Content.new(:name => "Sample Ticker",
  #                        :user => users(:katie),
  #                        :duration => 10)
  #  assert content.invalid?, "Content kind is blank"
  #  content.kind_id = 0
  #  assert content.invalid?, "Content kind is unassociated"
  #  content.kind = kinds(:ticker)
  #  assert content.valid?, "Content kind is associated with ticker"
  #end
  
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

  # start_time should correctly translate a hash
  # into a datetime object in addition to a string.
  test "start_time translation" do
    c = Content.new(:start_time => {:date => "4/12/2011", :time => "1:23 am"})
    assert_equal c.start_time.strftime('%Y-%m-%d %H:%M:%S'), "2011-04-12 01:23:00"

    c = Content.new(:start_time => "2011-04-12 01:34:00")
    assert_equal c.start_time.strftime('%Y-%m-%d %H:%M:%S'), "2011-04-12 01:34:00"
  end

  # end_time should correctly translate a hash
  # into a datetime object in addition to a string.
  test "end_time translation" do
    c = Content.new(:end_time => {:date => "4/12/2011", :time => "5:00 pm"})
    assert_equal c.end_time.strftime('%Y-%m-%d %H:%M:%S'), "2011-04-12 17:00:00"
    
    c = Content.new(:end_time => "2011-01-01 00:00:00")
    assert_equal c.end_time.strftime('%Y-%m-%d %H:%M:%S'), "2011-01-01 00:00:00"
  end

  test "content type scope works" do
    assert_no_difference 'Content.count', 'Unknown types does not change count'  do
      c = Content.new(:name => "Sample Ticker",
                      :kind_id => kinds(:ticker).id,
                      :duration => 10,
                      :user => users(:katie))
      c.type = 'UnknownType'
      assert c.save
    end
  end

end
