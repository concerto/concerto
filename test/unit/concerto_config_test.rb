require 'test_helper'

class ConcertoConfigTest < ActiveSupport::TestCase
  #Test the fields that should be required
  test "Config must return a default upload type of graphic" do
    assert_equal(ConcertoConfig[:default_upload_type], "graphic")
  end

  # Finders still work
  test "Can create or find by if needed" do
    assert_difference('ConcertoConfig.count', 1) do
      ConcertoConfig.find_or_create_by_key(:key => "foo", :value => "bar")
    end
  end

  # Attribute-style syntax works
  test "Attribute syntax" do
    assert_equal ConcertoConfig.default_upload_type, "graphic"
  end
end
