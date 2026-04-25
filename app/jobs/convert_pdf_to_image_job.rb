class ConvertPdfToImageJob < ApplicationJob
  queue_as :default

  retry_on Vips::Error, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(graphic)
    graphic.image.blob.open do |pdf|
      png = ImageProcessing::Vips
        .source(pdf)
        .loader(page: 0, dpi: 150)
        .convert("png")
        .call

      basename = File.basename(graphic.image.filename.to_s, ".pdf")
      graphic.image.attach(io: File.open(png.path), filename: "#{basename}.png", content_type: "image/png")
    end
  rescue => e
    graphic.update_column(:config, (graphic.config || {}).merge("conversion_error" => e.message))
    raise
  end
end
