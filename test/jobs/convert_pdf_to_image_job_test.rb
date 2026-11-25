require "test_helper"

class ConvertPdfToImageJobTest < ActiveJob::TestCase
  setup do
    @graphic = graphics(:pdf_graphic)
  end

  test "converts PDF attachment to PNG" do
    assert_equal "application/pdf", @graphic.image.content_type

    ConvertPdfToImageJob.perform_now(@graphic)

    @graphic.reload
    assert_equal "image/png", @graphic.image.content_type
    assert_nil @graphic.conversion_error
  end

  test "records error and re-raises on conversion failure" do
    # Raise RuntimeError (not Vips::Error) so retry_on doesn't swallow it
    pipeline_stub = Object.new
    pipeline_stub.define_singleton_method(:loader) { |**| self }
    pipeline_stub.define_singleton_method(:convert) { |_| self }
    pipeline_stub.define_singleton_method(:call) { raise "simulated conversion failure" }

    ImageProcessing::Vips.stub(:source, ->(_) { pipeline_stub }) do
      assert_raises(RuntimeError) do
        ConvertPdfToImageJob.perform_now(@graphic)
      end
    end

    @graphic.reload
    assert_not_nil @graphic.conversion_error
    assert_equal "application/pdf", @graphic.image.content_type
  end

  test "vips initializer allows standard image formats and PDFs while keeping other untrusted loaders blocked" do
    skip "libvips is not available" unless defined?(Vips)

    # Standard trusted image formats remain loadable
    jpeg = Vips::Image.new_from_file(file_fixture("template.jpg").to_s)
    assert_operator jpeg.width, :>, 0

    png = Vips::Image.new_from_file(file_fixture("template_portrait.png").to_s)
    assert_operator png.width, :>, 0

    # PDF loading is narrowly unblocked
    pdf = Vips::Image.new_from_file(file_fixture("flyer.pdf").to_s)
    assert_operator pdf.width, :>, 0

    # Other untrusted loaders remain blocked
    error = assert_raises(Vips::Error) do
      Vips::Operation.call("svgload_buffer", [ '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"></svg>' ])
    end
    assert_match(/operation is blocked/i, error.message)
  end
end
