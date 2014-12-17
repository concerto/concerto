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
        assert_equal expected_results[row][col], content.is_active?
      end
    end
  end

  # start_time should correctly translate a hash
  # into a datetime object in addition to a string.
  test "start_time translation" do
    Time.use_zone("UTC") do
      c = Content.new(:start_time => {:date => "4/12/2011", :time => "1:23 am"})
      assert_equal "2011-04-12 01:23:00", c.start_time.utc.strftime('%Y-%m-%d %H:%M:%S')

      c = Content.new(:start_time => "2014-12-15T05:00:00Z")
      assert_equal "2014-12-15T05:00:00Z", c.start_time.utc.iso8601
    end
  end

  # end_time should correctly translate a hash
  # into a datetime object in addition to a string.
  test "end_time iso8601" do
    Time.use_zone("UTC") do
      c = Content.new(:end_time => {:date => "4/12/2011", :time => "5:00 pm"})
      assert_equal "2011-04-12 17:00:00", c.end_time.utc.strftime('%Y-%m-%d %H:%M:%S')

      c = Content.new(:end_time => "2014-12-15T05:00:00Z")
      assert_equal "2014-12-15T05:00:00Z", c.end_time.utc.iso8601
    end
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

  test "content scope does not propogate" do
    graphics = Graphic.active
    graphics.each do |g|
      assert_equal "Graphic", g.class.name
    end
  end

  test "content subclasses all the way" do
    class TestContent < DynamicContent
    end
    subclasses = Content.all_subclasses
    assert subclasses.include?(Graphic)
    assert subclasses.include?(DynamicContent)
    assert subclasses.include?(TestContent)
    assert !subclasses.include?(Content)
  end

  test "default content allows no actions" do
    c = Content.new()
    assert !c.action_allowed?(:save, users(:katie))
  end

  test "default content does no actions" do
    c = Content.new()
    assert_equal nil, c.perform_action(:save, {:current_user => users(:katie)})
  end

  test "is_orphan? identifies content without submissions" do
    c = Ticker.new(:name => "Sample Ticker",
                   :data => 'Testing',
                   :kind_id => kinds(:ticker).id,
                   :duration => 10,
                   :user => users(:katie))
    assert c.save
    assert c.is_orphan?
  end

  test "is_denied? detects if content denied on any feed" do
    c = Ticker.new(:name => "TickerDeniedOnOne",
                   :data => 'Testing',
                   :duration => 10,
                   :user => users(:katie),
                   :start_time => 2.days.ago,
                   :end_time => Time.now.tomorrow)
    assert c.save

    Submission.create({:content => c, :duration => 5, :feed => feeds(:announcements)})
    assert !c.is_denied?
    assert Submission.create({
                      :content => c,
                      :duration => 5,
                      :feed => feeds(:boring_announcements),
                      :moderator => users(:admin),
                      :moderation_flag => true})
    assert !c.is_denied?
    assert Submission.create({
                      :content => c,
                      :duration => 5,
                      :feed => feeds(:important_announcements),
                      :moderator => users(:admin),
                      :moderation_flag => false})
    assert c.is_denied?
  end

  test "is_pending? detects if content pending on any feed" do
    c = Ticker.new(:name => "TickerPendingOnOne",
                   :data => 'Testing',
                   :duration => 10,
                   :user => users(:katie),
                   :start_time => 2.days.ago,
                   :end_time => Time.now.tomorrow)
    assert c.save

    assert Submission.create({
                      :content => c,
                      :duration => 5,
                      :feed => feeds(:boring_announcements),
                      :moderator => users(:admin),
                      :moderation_flag => true})
    assert !c.is_pending?
    assert Submission.create({
                      :content => c,
                      :duration => 5,
                      :feed => feeds(:important_announcements),
                      :moderator => users(:admin),
                      :moderation_flag => false})
    assert !c.is_pending?
    Submission.create({:content => c, :duration => 5, :feed => feeds(:announcements)})
    assert c.is_pending?
  end

  test "is_approved? true only when content is approved on all feeds" do
    c = Ticker.new(:name => "TickerApprovedOnAll",
                :data => 'Testing',
                :duration => 10,
                :user => users(:katie),
                :start_time => 2.days.ago,
                :end_time => Time.now.tomorrow)
    assert c.save

    assert Submission.create({
                      :content => c,
                      :duration => 5,
                      :feed => feeds(:boring_announcements),
                      :moderator => users(:admin),
                      :moderation_flag => true})
    assert c.is_approved?
    sub = Submission.create({
                      :content => c,
                      :duration => 5,
                      :feed => feeds(:important_announcements),
                      :moderator => users(:admin),
                      :moderation_flag => false})
    assert !c.is_approved?
    sub.moderation_flag = true
    sub.save
    assert c.is_approved?
    Submission.create({:content => c, :duration => 5, :feed => feeds(:announcements)})
    assert !c.is_approved?
  end

  test "base preview is empty" do
    assert_equal "", Content::preview
  end

  test "filter content by screen" do
    assert_equal 9, Content::filter_all_content({ :screen => screens(:one).id }).count
  end

  test "filter content by feed" do
    assert_equal 7, Content::filter_all_content({ :feed => feeds(:service).id }).count
  end

  test "filter content by user" do
    assert_equal 10, Content::filter_all_content({ :user => users(:katie).id }).count
  end

  test "filter content by type" do
    assert_equal 9, Content::filter_all_content({ :type => kinds(:ticker).id }).count
  end

  test "filter content by nothing returns all" do
    assert_equal 11, Content::filter_all_content({}).count
  end
end
