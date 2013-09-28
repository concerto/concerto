require 'test_helper'
require 'concerto_image_magick'

class ConcertoImageMagickTest < ActiveSupport::TestCase
  def setup
    @graphic_data = fixture_file_upload('/files/concerto_background.jpg', 'image/jpeg').read
  end

  def teardown
    @image = nil
  end

  test "load returns an image" do
    @image = ConcertoImageMagick.load_image(@graphic_data)
    assert @image.kind_of?(Magick::Image)

    assert_equal 1920, @image.columns
    assert_equal 1200, @image.rows
  end

  test "compute size simple resize" do
    size = ConcertoImageMagick.compute_size(100, 100, 200, 200)
    assert_equal 200, size[:width]
    assert_equal 200, size[:height]
  end

  test "compute size maintain ratio resize" do
    # Constrained width
    size = ConcertoImageMagick.compute_size(20, 10, 100, 100)
    assert_equal 100, size[:width]
    assert_equal 50, size[:height]

    # Constrained height
    size = ConcertoImageMagick.compute_size(10, 20, 100, 100)
    assert_equal 50, size[:width]
    assert_equal 100, size[:height]
  end

  test "compute size ignore ratio" do
    options = {:maintain_aspect_ratio => false}
    size = ConcertoImageMagick.compute_size(10, 20, 100, 100, options)
    assert_equal 100, size[:width]
    assert_equal 100, size[:height]
  end

  test "compute size maintain ratio single resize" do
    # Constrained width
    size = ConcertoImageMagick.compute_size(20, 10, 100, 0)
    assert_equal 100, size[:width]
    assert_equal 50, size[:height]

    size = ConcertoImageMagick.compute_size(10, 20, 100, 0)
    assert_equal 100, size[:width]
    assert_equal 200, size[:height]

    # Constrained height
    size = ConcertoImageMagick.compute_size(10, 20, 0, 100)
    assert_equal 50, size[:width]
    assert_equal 100, size[:height]

    size = ConcertoImageMagick.compute_size(20, 10, 0, 100)
    assert_equal 200, size[:width]
    assert_equal 100, size[:height]
  end

  test "compute size with expand to fit" do
    options = {:expand_to_fit => true}
    # Constrained width
    size = ConcertoImageMagick.compute_size(20, 10, 100, 100, options)
    assert_equal 200, size[:width]
    assert_equal 100, size[:height]

    # Constrained height
    size = ConcertoImageMagick.compute_size(10, 20, 100, 100, options)
    assert_equal 100, size[:width]
    assert_equal 200, size[:height]
  end

  test "resize resizes image" do
    @image = ConcertoImageMagick.load_image(@graphic_data)
    result = ConcertoImageMagick.resize(@image, 100, 200)
    assert_equal 100, result.columns
    assert_in_delta 61, result.rows, 2

    result = ConcertoImageMagick.resize(@image, 200, 100)
    assert_in_delta 165, result.columns, 5
    assert_equal 100, result.rows
  end

  test "resize with options" do
    @image = ConcertoImageMagick.load_image(@graphic_data)
    result = ConcertoImageMagick.resize(@image, 100, 200, true, true)
    assert_in_delta 330, result.columns, 10
    assert_equal 200, result.rows
  end

  test "crop image" do
    @image = ConcertoImageMagick.load_image(@graphic_data)
    result = ConcertoImageMagick.crop(@image, 100, 200)
    assert_equal 100, result.columns
    assert_equal 200, result.rows
  end
end
