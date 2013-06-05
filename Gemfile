# Edit this Gemfile to bundle your application's dependencies.
source 'https://rubygems.org'

gem "rails", "~> 4.0.0.rc1"

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

# Gems used for assets and not required
gem "sass-rails", "~> 4.0.0.rc1"
gem "coffee-rails", "~> 4.0.0"
gem 'therubyracer', :platforms => :ruby
gem 'execjs'
gem 'uglifier', '>= 1.3.0'

group :development do
  gem "better_errors", ">= 0.7.2"
  gem "binding_of_caller", ">= 0.7.1"
end if RUBY_VERSION >= "1.9"

gem 'jquery-rails'
gem 'turbolinks'
gem 'bootstrap-datepicker-rails'
gem 'jquery-timepicker-rails'

# In production we prefer MySQL over sqlite3.  If you are only
# interested in development and don't want to bother with production,
# run `bundle install --without production` to ignore MySQL.
gem "sqlite3", :group => [:development, :test]
gem "mysql2", :group => [:production]

#RMagick is used for image resizing and processing
gem "rmagick", ">= 2.12.2", :require => 'RMagick', :platforms => :ruby

# Attachable does all the file work.
gem 'attachable', '>= 0.0.5'

gem 'devise'
gem 'cancan'

gem 'json'

# Process jobs in the background
gem "delayed_job_active_record", "~> 4.0.0.beta2"
gem "daemons"

# Test Coverage
gem 'simplecov', :require => false, :group => :test

#Cross-platform monitoring of processes
gem 'sys-proctable'

gem 'rails-backup-migrate'

gem 'kaminari'  # Pagination

# Enable the newsfeed for 1.9+ users.
gem 'public_activity' if RUBY_VERSION >= "1.9"

