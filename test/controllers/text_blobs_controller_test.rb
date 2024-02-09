require "test_helper"

class TextBlobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @text_blob = text_blobs(:plaintext)
  end

  test "should get index" do
    get text_blobs_url
    assert_response :success
  end

  test "should get new" do
    get new_text_blob_url
    assert_response :success
  end

  test "should create text_blob" do
    assert_difference("TextBlob.count") do
      post text_blobs_url, params: { text_blob: { body: @text_blob.body, render_as: @text_blob.render_as,
        content_attributes: { name: @text_blob.content.name, duration: @text_blob.content.duration, start_time: @text_blob.content.start_time, end_time: @text_blob.content.end_time } } }
    end

    assert_redirected_to text_blob_url(TextBlob.last)
  end

  test "should show text_blob" do
    get text_blob_url(@text_blob)
    assert_response :success
  end

  test "should get edit" do
    get edit_text_blob_url(@text_blob)
    assert_response :success
  end

  test "should update text_blob" do
    patch text_blob_url(@text_blob), params: { text_blob: { body: @text_blob.body, render_as: @text_blob.render_as,
      content_attributes: { id: @text_blob.content.id, name: @text_blob.content.name, duration: @text_blob.content.duration, start_time: @text_blob.content.start_time, end_time: @text_blob.content.end_time } } }
    assert_redirected_to text_blob_url(@text_blob)
  end

  test "should destroy text_blob" do
    assert_difference("TextBlob.count", -1) do
      delete text_blob_url(@text_blob)
    end

    assert_redirected_to text_blobs_url
  end
end
