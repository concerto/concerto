require "test_helper"

class Frontend::ContentControllerTest < ActionDispatch::IntegrationTest
  test "should get main content" do
    get frontend_content_url(screen_id: screens(:one).id, field_id: fields(:main).id, position_id: positions(:two_graphic).id)
    assert_response :success
    assert_equal 1, response.parsed_body.length
  end

  test "should get ticker content" do
    get frontend_content_url(screen_id: screens(:two).id, field_id: fields(:ticker).id, position_id: positions(:two_ticker).id)
    assert_response :success
    assert_equal 2, response.parsed_body.length
  end

  test "should prefer active pinned content over subscriptions" do
    setup_pinned_content_scenario

    # Create active pinned content
    active_pinned_content = RichText.create!(
      name: "Pinned Content",
      text: "Pinned Content " * 20,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    # Create FieldConfig
    FieldConfig.create!(screen: @screen, field: @field, pinned_content: active_pinned_content)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    data = response.parsed_body
    # Should only contain pinned content
    assert_equal 1, data.length
    assert_equal active_pinned_content.id, data.first["id"]
  end

  test "should fallback to subscriptions if pinned content is expired" do
    setup_pinned_content_scenario

    # Create expired pinned content
    expired_pinned_content = RichText.create!(
      name: "Expired Pinned Content",
      text: "Expired Pinned Content " * 20,
      user: users(:admin),
      duration: 10,
      end_time: 1.day.ago,
      config: { render_as: "plaintext" }
    )

    FieldConfig.create!(screen: @screen, field: @field, pinned_content: expired_pinned_content)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    data = response.parsed_body
    # Should contain subscription content
    assert data.any? { |c| c["id"] == @active_subscription_content.id }
    # Should NOT contain pinned content (it's expired)
    assert_not data.any? { |c| c["id"] == expired_pinned_content.id }
  end

  test "should only return active content from subscriptions" do
    setup_subscription_scenario

    # Create active content (should be returned)
    active_content = RichText.create!(
      name: "Active Content",
      text: "Active Content " * 20,
      user: users(:admin),
      duration: 10,
      start_time: 1.hour.ago,
      end_time: 1.hour.from_now,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: active_content, feed: @feed)

    # Create expired content (should NOT be returned)
    expired_content = RichText.create!(
      name: "Expired Content",
      text: "Expired Content " * 20,
      user: users(:admin),
      duration: 10,
      start_time: 2.days.ago,
      end_time: 1.day.ago,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: expired_content, feed: @feed)

    # Create upcoming content (should NOT be returned)
    upcoming_content = RichText.create!(
      name: "Upcoming Content",
      text: "Upcoming Content " * 20,
      user: users(:admin),
      duration: 10,
      start_time: 1.hour.from_now,
      end_time: 2.hours.from_now,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: upcoming_content, feed: @feed)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    data = response.parsed_body
    # Should only contain active content
    assert_equal 1, data.length
    assert_equal active_content.id, data.first["id"]
    # Should NOT contain expired content
    assert_not data.any? { |c| c["id"] == expired_content.id }
    # Should NOT contain upcoming content
    assert_not data.any? { |c| c["id"] == upcoming_content.id }
  end

  test "should filter out expired subscription content" do
    setup_subscription_scenario

    # Create only expired content
    expired_content = RichText.create!(
      name: "Expired Content",
      text: "Expired Content " * 20,
      user: users(:admin),
      duration: 10,
      end_time: 1.day.ago,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: expired_content, feed: @feed)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    data = response.parsed_body
    # Should be empty (no active content)
    assert_equal 0, data.length
  end

  test "should filter out upcoming subscription content" do
    setup_subscription_scenario

    # Create only upcoming content
    upcoming_content = RichText.create!(
      name: "Upcoming Content",
      text: "Upcoming Content " * 20,
      user: users(:admin),
      duration: 10,
      start_time: 1.hour.from_now,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: upcoming_content, feed: @feed)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    data = response.parsed_body
    # Should be empty (no active content)
    assert_equal 0, data.length
  end

  test "should return content without start/end times from subscriptions" do
    setup_subscription_scenario

    # Create content without start/end times (always active)
    always_active_content = RichText.create!(
      name: "Always Active Content",
      text: "Always Active Content " * 20,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: always_active_content, feed: @feed)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    data = response.parsed_body
    # Should contain the always-active content
    assert_equal 1, data.length
    assert_equal always_active_content.id, data.first["id"]
  end

  private

  def setup_subscription_scenario
    @screen = screens(:one)
    @field = fields(:main)
    @position = positions(:one)

    # Cleanup existing data to avoid fixture interference
    Subscription.where(screen: @screen, field: @field).destroy_all
    FieldConfig.where(screen: @screen, field: @field).destroy_all

    # Setup feed and subscription
    @feed = Feed.create!(name: "Test Feed", group: groups(:feed_one_owners))
    Subscription.create!(screen: @screen, field: @field, feed: @feed)
  end

  def setup_pinned_content_scenario
    @screen = screens(:one)
    @field = fields(:main)
    @position = positions(:one)

    # Cleanup existing data to avoid fixture interference
    Subscription.where(screen: @screen, field: @field).destroy_all
    FieldConfig.where(screen: @screen, field: @field).destroy_all

    # Setup common subscription content
    @feed = Feed.create!(name: "Test Feed", group: groups(:feed_one_owners))
    @active_subscription_content = RichText.create!(
      name: "Subscription Content",
      text: "Subscription Content " * 20,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: @active_subscription_content, feed: @feed)
    Subscription.create!(screen: @screen, field: @field, feed: @feed)
  end
end
