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

      begin
        graphic.image.attach(io: png, filename: "#{graphic.image.filename.base}.png", content_type: "image/png")
      ensure
        png.close!
      end
    end
  rescue => e
    graphic.update_column(:config, (graphic.config || {}).merge("conversion_error" => e.message))
    raise
  end
end
