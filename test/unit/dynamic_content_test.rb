require 'test_helper'
include ActionDispatch::TestProcess

class DynamicContentTest < ActiveSupport::TestCase

  class TestHarness < DynamicContent
    attr_accessor :force_failure

    def build_content
      if @force_failure
        return false
      else
        return [HtmlText.new({ :name => 'sample', :duration => 13, :data => '<p>Sample</p>'})]
      end
    end
  end

  test "New config is created" do
    dynamic = DynamicContent.new
    assert_equal({}.class, dynamic.config.class)
    dynamic.config['var'] = 'foo'
    assert_equal 'foo', dynamic.config['var']
  end

  test "Save and load config" do
    dynamic = DynamicContent.new
    dynamic.config['var'] = 'foo'
    dynamic.config['other'] = 123
    dynamic.save_config

    dynamic.config = nil
    dynamic.load_config

    assert_equal 'foo', dynamic.config['var']
    assert_equal 123, dynamic.config['other']
  end

  test "Auto save and load" do
    dynamic = DynamicContent.new
    dynamic.name = 'Dynamic Content'
    dynamic.user = users(:katie)
    dynamic.config['var'] = 'foo'
    dynamic.config['other'] = 123
    dynamic.save

    fresh = DynamicContent.find(dynamic.id)
    assert_equal 'foo', fresh.config['var']
    assert_equal 123, fresh.config['other']
  end
  
  test "Expire children is called" do
    dynamic = DynamicContent.where("name = 'Sample Dynamic Content Feed'").first
    child = Ticker.where("name = 'Concerto TV Google Play'").first
    
    assert !child.is_expired?
    dynamic.expire_children
    
    child.reload
    assert child.is_expired?
  end

  test "Purge children is called" do
    dynamic = DynamicContent.where("name = 'Sample Dynamic Content Feed'").first
    dynamic.destroy_children!
    child = Ticker.where("name = 'Concerto TV Google Play'").first
    assert child.nil?
  end

  test "refresh failure sets last_bad_refresh" do
    dynamic = TestHarness.new({:name => 'test', :user => users(:katie)})
    dynamic.force_failure = true

    assert dynamic.config['last_ok_refresh'].nil?
    assert dynamic.config['last_bad_refresh'].nil?
    assert dynamic.config['last_refresh_attempt'].nil?
    assert dynamic.refresh!
    assert dynamic.config['last_ok_refresh'].nil?
    assert !dynamic.config['last_bad_refresh'].nil?
    assert !dynamic.config['last_refresh_attempt'].nil?
  end

  test "refresh success sets last_ok_refresh" do
    dynamic = TestHarness.new({:name => 'test', :user => users(:katie)})

    assert dynamic.config['last_ok_refresh'].nil?
    assert dynamic.config['last_bad_refresh'].nil?
    assert dynamic.config['last_refresh_attempt'].nil?
    assert dynamic.refresh
    assert !dynamic.config['last_ok_refresh'].nil?
    assert dynamic.config['last_bad_refresh'].nil?
    assert !dynamic.config['last_refresh_attempt'].nil?
  end

  test "refresh_needed? false when no interval specified" do
    dynamic = TestHarness.new({:name => 'test', :user => users(:katie)})
    dynamic.config.delete('interval')
    assert !dynamic.refresh_needed?
  end

  test "refresh_needed? true when interval exists and never updated" do
    dynamic = TestHarness.new({:name => 'test', :user => users(:katie)})
    assert dynamic.refresh_needed?
  end

  test "refresh_needed? true when interval exists and time has expired" do
    dynamic = TestHarness.new({:name => 'test', :user => users(:katie), 
      :config => { :last_refresh_attempt => Clock.time.to_i - 900 }})
    assert dynamic.refresh_needed?

    # not needed if time hasn't expired
    dynamic.config['last_refresh_attempt'] = Clock.time.to_i
    assert !dynamic.refresh_needed?
  end

  test "refresh class method refreshes the content" do
    dynamic = TestHarness.create({:name => 'test', :duration => 8, :user => users(:katie) })
    submission = Submission.create(:content => dynamic, :feed => feeds(:service), 
      :duration => 5, :moderator => users(:katie), :moderation_flag => true)

    assert dynamic.config['last_refresh_attempt'].nil?
    Concerto::Application.config.content_types.push(TestHarness)
    DynamicContent::refresh
    dynamic = TestHarness.find(dynamic.id)

    assert !dynamic.config['last_refresh_attempt'].nil?

    # check that a new child's submission matches the parent's submission
    ticker = dynamic.children.first
    ticker_submission = ticker.submissions.first
    assert submission.feed.id == ticker_submission.feed.id and 
      submission.duration == ticker_submission.duration and 
      submission.moderator.id == ticker_submission.moderator.id and
      submission.moderation_flag == ticker_submission.moderation_flag and 
      ticker_submission.duration == 8

    # change the parent's submission and make sure an updated child reflects it
    submission.duration = 17
    submission.save
    dynamic.refresh!
    dynamic = TestHarness.find(dynamic.id)
    ticker = dynamic.children.first
    ticker_submission = ticker.submissions.first
    assert submission.feed.id == ticker_submission.feed.id and 
      submission.duration == ticker_submission.duration and 
      submission.moderator.id == ticker_submission.moderator.id and
      submission.moderation_flag == ticker_submission.moderation_flag and
      ticker_submission.duration == 17
  end

  test "default build_content returns empty array" do
    dynamic = DynamicContent.new
    assert_equal [], dynamic.build_content
  end

  test "allowed actions" do
    dynamic = DynamicContent.new
    assert dynamic.action_allowed?(:manual_refresh, nil)
    assert dynamic.action_allowed?(:delete_children, nil)
    assert !dynamic.action_allowed?(:bogus_action, nil)
  end

  test "manual_refresh"  do
    dynamic = TestHarness.create({:name => 'test', :duration => 8, :user => users(:katie) })
    assert dynamic.manual_refresh({:current_user => users(:katie)}).include?('successfully')

    dynamic = TestHarness.create({:name => 'test', :duration => 8, :user => users(:kristen) })
    assert dynamic.manual_refresh({:current_user => users(:katie)}).include?("don't have access")
  end

  test "delete_children"  do
    dynamic = TestHarness.create({:name => 'test', :duration => 8, :user => users(:katie) })
    assert dynamic.delete_children({:current_user => users(:katie)}).include?('successfully')

    dynamic = TestHarness.create({:name => 'test', :duration => 8, :user => users(:kristen) })
    assert dynamic.delete_children({:current_user => users(:katie)}).include?("don't have access")
  end
end
