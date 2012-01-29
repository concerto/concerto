# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
Mime::Type.register "image/jpg", :jpg unless Mime::Type.lookup_by_extension(:jpg)
Mime::Type.register "image/png", :png unless Mime::Type.lookup_by_extension(:png)
Mime::Type.register "image/svg+xml", :svg unless Mime::Type.lookup_by_extension(:svg)
