require "test_helper"

class IframeTest < ActiveSupport::TestCase
  setup do
    @iframe = iframes(:iframe_example)
  end

  test "is valid with an http(s) url" do
    assert @iframe.valid?

    @iframe.url = "http://example.org"
    assert @iframe.valid?
  end

  test "requires a url" do
    @iframe.url = ""
    assert_not @iframe.valid?
    assert_includes @iframe.errors[:url], "can't be blank"
  end

  test "rejects non-http schemes" do
    @iframe.url = "javascript:alert(1)"
    assert_not @iframe.valid?
    assert_includes @iframe.errors[:url], "must be a valid http or https URL"
  end

  test "rejects urls without a host" do
    @iframe.url = "https://"
    assert_not @iframe.valid?
    assert_includes @iframe.errors[:url], "must be a valid http or https URL"
  end

  test "rejects malformed urls" do
    @iframe.url = "http://exa mple.com"
    assert_not @iframe.valid?
    assert_includes @iframe.errors[:url], "is not a valid URL"
  end

  test "as_json exposes url and type" do
    json = @iframe.as_json
    assert_equal "https://example.com/dashboard", json[:url]
    assert_equal "Iframe", json["type"]
  end

  test "searchable_data includes name and url" do
    data = @iframe.searchable_data
    assert_equal "Sample Web Page", data[:name]
    assert_equal "https://example.com/dashboard", data[:body]
  end
end
