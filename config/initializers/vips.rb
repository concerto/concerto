# image_processing 2.0 blocks unfuzzed loaders (including pdfload) by default.
# Eagerly require it here so we can restore PDF loading after the global block
# is set, since this app processes admin-uploaded PDFs via ConvertPdfToImageJob.
# Rescue gracefully on hosts where libvips is not installed (e.g. CI scan jobs).
begin
  require "image_processing/vips"
  Vips.block_untrusted(false) if Vips.respond_to?(:block_untrusted)
rescue LoadError
  # libvips not available; PDF→PNG conversion will be unavailable
end
