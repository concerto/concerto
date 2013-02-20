# Edit this Gemfile to bundle your application's dependencies.
source 'https://rubygems.org'

gem "rails", "3.2.11"

# Get the absolute path of this Gemfile so the includes below still work
# when the current directory for a bundler command isn't the application's
# root directory.
basedir = File.dirname(__FILE__)

# Load the gems used for remote reporting.
if File.exists?(basedir+'/Gemfile-reporting')
  eval File.read(basedir+'/Gemfile-reporting')
end

# The Gemfile-plugins gem list is managed by Concerto itself,
# through the ConcertoPlugins controller.
group :concerto_plugins do
  eval File.read(basedir+'/Gemfile-plugins')
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'therubyracer'
  gem 'execjs'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'turbolinks'
gem 'jquery-timepicker-rails'

# In production we prefer MySQL over sqlite3.  If you are only
# interested in development and don't want to bother with production,
# run `bundle install --without production` to ignore MySQL.
gem "sqlite3", :group => [:development, :test]
gem "mysql2", :group => [:production]

#RMagick is used for image resizing and processing
gem "rmagick", ">= 2.12.2", :require => 'RMagick'

# Attachable does all the file work.
gem 'attachable', '>= 0.0.5'

gem 'devise'
gem 'cancan'

gem 'json'

# Process jobs in the background
gem 'delayed_job_active_record'
gem "daemons"

# Test Coverage
gem 'simplecov', :require => false, :group => :test

#Cross-platform monitoring of processes
gem 'sys-proctable'

gem 'rails-backup-migrate'

gem 'strong_parameters'

# Default plugins.
# We should move these to gems when we're releasing, but for now we'll develop with git repos.
gem 'c2_simple_rss', :git => 'git://github.com/concerto/c2_simplerss.git'
