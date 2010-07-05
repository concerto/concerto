require 'test_helper'

class ContentsHelperTest < ActionView::TestCase

  test "all content_types are subclasses of Content" do
    content_types.each do |content_type|
      assert_equal content_type.superclass, Content
    end
  end
end
