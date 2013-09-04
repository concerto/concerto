require 'test_helper'

class MediaTest < ActiveSupport::TestCase
  # Attributes cannot be left empty/blank
  test "media attributes must not be empty" do
    media = Media.new
    assert media.invalid?
    assert media.errors[:file_type].any?
    assert media.errors[:file_size].any?
  end

  test "media preferred scope is 'processed' then 'original'" do
    t = templates(:one)
    assert_equal t.media.size, 2, "template one does not have two media entries"
    assert t.media.original.first.key == 'original', "original media entry is missing"
    assert t.media.processed.first.key == 'processed', "processed media entry is missing"
    assert t.media.preferred.first.key == 'processed', "processed entry should come before original entry"
  end
end
