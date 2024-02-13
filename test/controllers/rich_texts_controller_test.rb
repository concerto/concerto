require "test_helper"

class RichTextsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rich_text = rich_texts(:plain_richtext)
  end

  test "should get index" do
    get rich_texts_url
    assert_response :success
  end

  test "should get new" do
    get new_rich_text_url
    assert_response :success
  end

  test "should create rich_text" do
    assert_difference("RichText.count") do
      post rich_texts_url, params: { rich_text: {
        duration: @rich_text.duration, end_time: @rich_text.end_time,
        name: @rich_text.name, start_time: @rich_text.start_time, text: @rich_text.text, render_as: @rich_text.render_as,
        feed_ids: @rich_text.feed_ids
        } }
    end

    assert_redirected_to rich_text_url(RichText.last)
  end

  test "should show rich_text" do
    get rich_text_url(@rich_text)
    assert_response :success
  end

  test "should get edit" do
    get edit_rich_text_url(@rich_text)
    assert_response :success
  end

  test "should update rich_text" do
    patch rich_text_url(@rich_text), params: { rich_text: {
      duration: @rich_text.duration, end_time: @rich_text.end_time,
      name: @rich_text.name, start_time: @rich_text.start_time, text: @rich_text.text, render_as: @rich_text.render_as,
      feed_ids: @rich_text.feed_ids  } }
    assert_redirected_to rich_text_url(@rich_text)
  end

  test "should destroy rich_text" do
    assert_difference("RichText.count", -1) do
      delete rich_text_url(@rich_text)
    end

    assert_redirected_to rich_texts_url
  end
end
