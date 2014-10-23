# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder
# are already added.
Rails.application.config.assets.precompile += %w( html5_shiv/html5.js )
# The HTML 5 Shiv is kep outside of application.js because it is
# loaded conditionally for IE.

