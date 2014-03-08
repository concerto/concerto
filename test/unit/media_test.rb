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
    assert_equal 2, t.media.size, "template one does not have two media entries"
    assert t.media.original.first.key == 'original', "original media entry is missing"
    assert t.media.processed.first.key == 'processed', "processed media entry is missing"
    assert t.media.preferred.first.key == 'processed', "processed entry should come before original entry"
  end

  test "cleanup previews" do
    before_count = Media.where("media.key = 'preview'").count
    recent = Media.create({:key => 'preview', :file_type => 'png', :file_size => 0})
    old = Media.create({:key => 'preview', :file_type => 'png', :file_size => 0})
    old.created_at = DateTime.new(2000, 1, 1)
    old.save
    after_count = Media.where("media.key = 'preview'").count
    assert after_count == before_count + 2
    Media.cleanup_previews
    after_count = Media.where("media.key = 'preview'").count
    assert after_count == before_count + 1
  end

  test "valid previews" do
    recent = Media.create({:key => 'preview', :file_type => 'png', :file_size => 0, :attachable_id => 0})
    old = Media.create({:key => 'preview', :file_type => 'png', :file_size => 0, :attachable_id => 0})
    old.created_at = DateTime.new(2000, 1, 1)
    old.save

    assert Media::valid_preview(recent.id)
    assert !Media::valid_preview(old.id)
  end
end
