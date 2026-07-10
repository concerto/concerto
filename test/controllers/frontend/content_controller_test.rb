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

  test "should use random ordering by default" do
    setup_subscription_scenario

    content1 = RichText.create!(
      name: "Content 1",
      text: "Content 1 " * 20,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: content1, feed: @feed)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    # Verify content is returned (ordering is non-deterministic)
    assert response.parsed_body.any?
  end

  test "should use weighted ordering when configured" do
    setup_subscription_scenario

    # Create FieldConfig with weighted strategy
    FieldConfig.create!(
      screen: @screen,
      field: @field,
      ordering_strategy: "weighted"
    )

    content1 = RichText.create!(
      name: "Content 1",
      text: "Content 1 " * 20,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: content1, feed: @feed)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    # Note: This test verifies that the weighted strategy is applied without errors.
    # It does not verify the actual weighting behavior - that's covered by unit tests.
    assert response.parsed_body.any?
  end

  test "should use strict priority ordering when configured" do
    setup_subscription_scenario

    # Create FieldConfig with strict_priority strategy
    FieldConfig.create!(
      screen: @screen,
      field: @field,
      ordering_strategy: "strict_priority"
    )

    content1 = RichText.create!(
      name: "Content 1",
      text: "Content 1 " * 20,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: content1, feed: @feed)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    # Verify content is returned
    assert response.parsed_body.any?
  end

  test "should apply ordering strategy to multiple feeds" do
    setup_subscription_scenario

    # Create another feed with higher weight
    feed2 = Feed.create!(name: "High Priority Feed", group: groups(:feed_one_owners))
    subscription2 = Subscription.create!(screen: @screen, field: @field, feed: feed2, weight: 10)

    # Set original subscription to lower weight
    Subscription.find_by(screen: @screen, field: @field, feed: @feed).update!(weight: 2)

    # Create FieldConfig with strict_priority strategy
    FieldConfig.create!(
      screen: @screen,
      field: @field,
      ordering_strategy: "strict_priority"
    )

    # Add content to lower priority feed
    low_content = RichText.create!(
      name: "Low Priority Content",
      text: "Low Priority Content " * 20,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: low_content, feed: @feed)

    # Add content to high priority feed
    high_content = RichText.create!(
      name: "High Priority Content",
      text: "High Priority Content " * 20,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: high_content, feed: feed2)

    get frontend_content_url(screen_id: @screen.id, field_id: @field.id, position_id: @position.id)
    assert_response :success

    data = response.parsed_body
    # Should only contain high priority content
    assert_equal 1, data.length
    assert_equal high_content.id, data.first["id"]
  end

  test "renders content only in its best-fit field when a feed spans multiple fields" do
    setup_multi_field_scenario

    # ~150 chars fits the large Main position better than the smaller Sidebar.
    main_content = create_richtext("a" * 150)
    # ~120 chars fits the Sidebar's capacity more closely than Main.
    sidebar_content = create_richtext("b" * 120)

    main_ids = ids_for(field: fields(:main), position: positions(:two_graphic))
    sidebar_ids = ids_for(field: fields(:sidebar), position: positions(:two_sidebar))

    assert_includes main_ids, main_content.id
    assert_not_includes main_ids, sidebar_content.id

    assert_includes sidebar_ids, sidebar_content.id
    assert_not_includes sidebar_ids, main_content.id

    # Every piece of content renders in exactly one of the two fields.
    assert_equal [ main_content.id, sidebar_content.id ].sort, (main_ids + sidebar_ids).sort
  end

  test "drops content that fits no subscribed field" do
    # Subscribe the feed only to the two small fields (Sidebar and Ticker),
    # neither of which can hold a wall of text.
    setup_multi_field_scenario(fields: [ fields(:sidebar), fields(:ticker) ])

    huge = create_richtext("c" * 1000)   # overflows both small fields
    small = create_richtext("d" * 50)    # fits, best in the Ticker

    sidebar_ids = ids_for(field: fields(:sidebar), position: positions(:two_sidebar))
    ticker_ids = ids_for(field: fields(:ticker), position: positions(:two_ticker))

    # The oversized content fits nowhere and is dropped from every field.
    assert_not_includes sidebar_ids, huge.id
    assert_not_includes ticker_ids, huge.id

    # The small content still renders, in its best-fit field only.
    assert_includes ticker_ids, small.id
    assert_not_includes sidebar_ids, small.id
  end

  test "should include config version header" do
    screen = screens(:one)
    get frontend_content_url(screen_id: screen.id, field_id: fields(:main).id, position_id: positions(:two_graphic).id)
    assert_response :success

    config_version = response.headers["X-Config-Version"]
    assert_not_nil config_version
    assert_equal 32, config_version.length
    assert_match(/^[a-f0-9]{32}$/, config_version)
  end

  private

  # Screen 1 (Template Two) with one feed subscribed to several fields, so the
  # same content is a candidate for multiple positions and must be deduped.
  def setup_multi_field_scenario(fields: [ fields(:main), fields(:sidebar) ])
    @screen = screens(:one)
    Subscription.where(screen: @screen).destroy_all
    FieldConfig.where(screen: @screen).destroy_all

    @feed = Feed.create!(name: "Multi-field Feed", group: groups(:feed_one_owners))
    fields.each { |field| Subscription.create!(screen: @screen, field: field, feed: @feed) }
  end

  def create_richtext(text)
    content = RichText.create!(
      name: "Content #{text.first}#{text.length}",
      text: text,
      user: users(:admin),
      duration: 10,
      config: { render_as: "plaintext" }
    )
    Submission.create!(content: content, feed: @feed)
    content
  end

  def ids_for(field:, position:)
    get frontend_content_url(screen_id: @screen.id, field_id: field.id, position_id: position.id)
    assert_response :success
    response.parsed_body.map { |c| c["id"] }
  end

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
