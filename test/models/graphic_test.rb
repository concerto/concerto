require "test_helper"

class GraphicTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @graphic = graphics(:one)
  end

  test "has analyzed metadata" do
    assert_equal 4080, @graphic.image.metadata[:width]
    assert_equal 3072, @graphic.image.metadata[:height]
  end

  test "should render images in appropriate fields" do
    assert @graphic.should_render_in?(positions(:two_graphic))

    assert_not @graphic.should_render_in?(positions(:two_ticker))
  end

  test "does not render when image is still a PDF" do
    assert_not graphics(:pdf_graphic).should_render_in?(positions(:two_graphic))
  end

  test "enqueues conversion job when PDF is attached on create" do
    graphic = Graphic.new(name: "PDF Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("flyer.pdf").open, filename: "flyer.pdf", content_type: "application/pdf")

    assert_enqueued_with(job: ConvertPdfToImageJob) do
      graphic.save!
    end
  end

  test "enqueues conversion job when PDF replaces existing image on update" do
    assert_enqueued_with(job: ConvertPdfToImageJob) do
      @graphic.image.attach(io: file_fixture("flyer.pdf").open, filename: "flyer.pdf", content_type: "application/pdf")
      @graphic.save!
    end
  end

  test "does not enqueue conversion job when a regular image is attached" do
    graphic = Graphic.new(name: "Image Test", duration: 10, user: users(:admin))
    graphic.image.attach(io: file_fixture("one.jpg").open, filename: "one.jpg", content_type: "image/jpeg")

    assert_no_enqueued_jobs(only: ConvertPdfToImageJob) do
      graphic.save!
    end
  end
end
