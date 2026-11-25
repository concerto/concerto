# image_processing 2.0 enables Vips.block_untrusted(true) by default to block
# unfuzzed loaders (such as svgload, magickload, and pdfload).
# Eagerly require it here and narrowly unblock only PDF loading so
# ConvertPdfToImageJob can convert uploaded PDFs while keeping other untrusted
# loaders blocked.
# Rescue gracefully on hosts where libvips is not installed (e.g. CI scan jobs).
begin
  require "image_processing/vips"
  Vips.block("VipsForeignLoadPdf", false) if Vips.respond_to?(:block)
rescue LoadError
  # libvips not available; PDF→PNG conversion will be unavailable
end
