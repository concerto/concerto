# This file override's Passenger's default Bundler handling. When
# Passenger sees this file it will run it instead of trying to load
# the Gemfile automatically. The code in config/boot.rb will attempt
# to auto-install gems to vendor/bundle if any are missing, for example
# on the first reboot after install a plugin. The code will then 
# continue to actually call Bundler and load the gems from our Gemfile.
require File.expand_path('../boot.rb', __FILE__)
