require "test_helper"

class RichTextsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rich_text = rich_texts(:plain_richtext)
    @user = users(:admin)
  end

  test "should show rich_text when not logged in" do
    get rich_text_url(@rich_text)
    assert_response :success
  end

  test "should redirect new when not logged in" do
    get new_rich_text_url
    assert_redirected_to new_user_session_url
  end

  test "should get new when logged in" do
    sign_in @user
    get new_rich_text_url
    assert_response :success
  end

  test "should redirect create when not logged in" do
    assert_no_difference("RichText.count") do
      post rich_texts_url, params: { rich_text: {
        duration: @rich_text.duration, end_time: @rich_text.end_time,
        name: @rich_text.name, start_time: @rich_text.start_time,
        text: @rich_text.text, render_as: @rich_text.render_as,
        feed_ids: @rich_text.feed_ids
      } }
    end
    assert_redirected_to new_user_session_url
  end

  test "should create rich_text when logged in" do
    sign_in @user
    assert_difference("RichText.count") do
      post rich_texts_url, params: { rich_text: {
        duration: @rich_text.duration, end_time: @rich_text.end_time,
        name: @rich_text.name, start_time: @rich_text.start_time,
        text: @rich_text.text, render_as: @rich_text.render_as,
        feed_ids: @rich_text.feed_ids
      } }
    end
    assert_redirected_to rich_text_url(RichText.last)
  end

  test "should redirect edit when not logged in" do
    get edit_rich_text_url(@rich_text)
    assert_redirected_to new_user_session_url
  end

  test "should get edit when logged in" do
    sign_in @user
    get edit_rich_text_url(@rich_text)
    assert_response :success
  end

  test "should redirect update when not logged in" do
    patch rich_text_url(@rich_text), params: { rich_text: {
      duration: @rich_text.duration, end_time: @rich_text.end_time,
      name: @rich_text.name, start_time: @rich_text.start_time,
      text: @rich_text.text, render_as: @rich_text.render_as,
      feed_ids: @rich_text.feed_ids
    } }
    assert_redirected_to new_user_session_url
  end

  test "should update rich_text when logged in" do
    sign_in @user
    patch rich_text_url(@rich_text), params: { rich_text: {
      duration: @rich_text.duration, end_time: @rich_text.end_time,
      name: @rich_text.name, start_time: @rich_text.start_time,
      text: @rich_text.text, render_as: @rich_text.render_as,
      feed_ids: @rich_text.feed_ids
    } }
    assert_redirected_to rich_text_url(@rich_text)
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference("RichText.count") do
      delete rich_text_url(@rich_text)
    end
    assert_redirected_to new_user_session_url
  end

  test "should destroy rich_text when logged in" do
    sign_in @user
    assert_difference("RichText.count", -1) do
      delete rich_text_url(@rich_text)
    end
    assert_response :see_other
    assert_redirected_to contents_url
  end

  # Authorization tests
  test "should not allow non-owner to edit content" do
    sign_in users(:non_member)
    get edit_rich_text_url(@rich_text), headers: { "Referer" => rich_text_url(@rich_text) }
    assert_redirected_to rich_text_url(@rich_text)
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should not allow non-owner to update content" do
    sign_in users(:non_member)
    patch rich_text_url(@rich_text), params: { rich_text: {
      name: "Unauthorized update"
    } }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    @rich_text.reload
    assert_not_equal "Unauthorized update", @rich_text.name
  end

  test "should not allow non-owner to destroy content" do
    sign_in users(:non_member)
    assert_no_difference("RichText.count") do
      delete rich_text_url(@rich_text)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should allow owner to edit their content" do
    sign_in @user
    get edit_rich_text_url(@rich_text)
    assert_response :success
  end

  test "should allow owner to update their content" do
    sign_in @user
    patch rich_text_url(@rich_text), params: { rich_text: {
      name: "Updated by owner"
    } }
    assert_redirected_to rich_text_url(@rich_text)
    @rich_text.reload
    assert_equal "Updated by owner", @rich_text.name
  end

  test "should allow owner to destroy their content" do
    sign_in @user
    assert_difference("RichText.count", -1) do
      delete rich_text_url(@rich_text)
    end
    assert_redirected_to contents_url
  end

  # Submission visibility tests
  test "anonymous user sees approved feed but not pending feed on show page" do
    get rich_text_url(@rich_text)
    assert_response :success
    # plain_richtext has approved submission to Feed Two and pending to Feed One
    assert_select "a", text: feeds(:two).name
    assert_select "a", text: feeds(:one).name, count: 0
  end

  test "content owner sees all submissions with status badges on show page" do
    sign_in @user
    get rich_text_url(@rich_text)
    assert_response :success
    assert_select "a", text: feeds(:two).name
    assert_select "a", text: feeds(:one).name
    assert_select "span", text: "Pending"
    assert_select "span", text: "Approved"
  end

  test "non-member submitting to RSS and Remote feeds creates pending submissions" do
    sign_in users(:non_member)
    rss_feed = rss_feeds(:yahoo_rssfeed)
    remote_feed = remote_feeds(:system_remote_feed)

    assert_difference("RichText.count") do
      post rich_texts_url, params: { rich_text: {
        duration: 10,
        name: "External Submission",
        text: "Hello",
        render_as: "plaintext",
        feed_ids: [ rss_feed.id, remote_feed.id ]
      } }
    end

    created = RichText.last
    assert_equal 2, created.submissions.count
    assert created.submissions.all?(&:pending?), "Non-member submissions to RSS/Remote feeds must be pending"
  end

  # Moderator HTML security warning tests
  test "plaintext rich text show page displays no HTML warning" do
    get rich_text_url(@rich_text)
    assert_response :success
    assert_select "[data-rich-text-warning]", count: 0
  end

  test "safe HTML rich text show page displays subtle HTML notice with raw source toggle" do
    safe_html = RichText.create!(
      name: "Safe HTML",
      text: "<h1>Welcome</h1><p>Hello world</p>",
      duration: 10,
      user: @user,
      config: { "render_as" => "html" }
    )

    get rich_text_url(safe_html)
    assert_response :success
    assert_select "[data-rich-text-warning='html-notice']", count: 1
    assert_select "[data-rich-text-warning='active-html']", count: 0
    assert_select "details summary", text: /View raw HTML source/
    assert_select "details pre code", text: safe_html.text
  end

  test "HTML rich text with script tag displays active HTML warning and escaped raw source" do
    script_html = RichText.create!(
      name: "Script HTML",
      text: "<script>alert('xss')</script>",
      duration: 10,
      user: @user,
      config: { "render_as" => "html" }
    )

    get rich_text_url(script_html)
    assert_response :success
    assert_select "[data-rich-text-warning='active-html']", count: 1
    assert_select "[data-rich-text-warning='active-html']", text: /<script> element/
    assert_select "details pre code", text: "<script>alert('xss')</script>"
    assert_select "div.prose script", count: 0
  end

  test "HTML rich text stripped to empty displays empty preview fallback" do
    iframe_html = RichText.create!(
      name: "Iframe HTML",
      text: '<iframe src="https://evil.example/embed"></iframe>',
      duration: 10,
      user: @user,
      config: { "render_as" => "html" }
    )

    get rich_text_url(iframe_html)
    assert_response :success
    assert_select "[data-rich-text-warning='active-html']", count: 1
    assert_select "[data-rich-text-warning='active-html']", text: /<iframe> element/
    assert_select "div.prose", text: /No visible content remains in the sanitized preview/
  end

  test "HTML rich text with inline event handler displays active HTML warning" do
    handler_html = RichText.create!(
      name: "Handler HTML",
      text: '<img src="https://example.com/pic.png" onerror="alert(1)">',
      duration: 10,
      user: @user,
      config: { "render_as" => "html" }
    )

    get rich_text_url(handler_html)
    assert_response :success
    assert_select "[data-rich-text-warning='active-html']", count: 1
    assert_select "[data-rich-text-warning='active-html']", text: /inline event handler \(onerror\)/
  end
end
