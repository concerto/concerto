require 'test_helper'

class ContentsHelperTest < ActionView::TestCase

  test "all content_types are eventually subclasses of Content" do
    content_types.each do |content_type|
      assert content_type.ancestors.include?(Content), "Trouble with #{content_type}."
    end
  end
end
