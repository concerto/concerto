require 'test_helper'

class MediaTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "media attributes must not be empty" do
    media = Media.new
    assert media.invalid?
    assert media.errors[:file_type].any?
    assert media.errors[:file_size].any?
  end
end
