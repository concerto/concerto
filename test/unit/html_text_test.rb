require 'test_helper'
include ActionDispatch::TestProcess

class HtmlTextTest < ActiveSupport::TestCase
  # Default Kind only applies if unset
  test "html text sets kind if needed" do
    content = HtmlText.new(:kind => kinds(:ticker))
    assert_equal content.kind, kinds(:ticker)

    content = HtmlText.new()
    assert_equal content.kind, kinds(:text)
  end
end
