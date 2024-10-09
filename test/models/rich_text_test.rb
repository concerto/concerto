require "test_helper"

class RichTextTest < ActiveSupport::TestCase
  test "Should be rendered in all positions" do
    Position.all.each do |p|
      assert rich_texts(:plain_richtext).should_render_in?(p)
    end
  end
end
