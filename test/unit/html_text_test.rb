require 'test_helper'
include ActionDispatch::TestProcess

class HtmlTextTest < ActiveSupport::TestCase
  # Default Kind only applies if unset
  test "html text sets kind if needed" do
    content = HtmlText.new(:kind => kinds(:ticker))
    assert_equal kinds(:ticker), content.kind

    content = HtmlText.new()
    assert_equal kinds(:text), content.kind
  end
end
