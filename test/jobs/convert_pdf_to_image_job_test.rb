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
end
