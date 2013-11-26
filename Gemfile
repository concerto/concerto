# Edit this Gemfile to bundle your application's dependencies.
source 'https://rubygems.org'

gem "rails", "~> 3.2.15"

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
  eval File.read(basedir+'/Gemfile-plugins') if File.exists?(basedir+'/Gemfile-plugins')
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"
  gem 'therubyracer', :platforms => :ruby
  gem 'execjs'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'turbolinks'
gem 'bootstrap-datepicker-rails'
gem 'jquery-timepicker-rails'
gem 'twitter-bootstrap-rails-confirm'

# In production we prefer MySQL over sqlite3.  If you are only
# interested in development and don't want to bother with production,
# run `bundle install --without production` to ignore MySQL.
gem "sqlite3", :group => [:development, :test]
gem "mysql2", :group => [:production]

#RMagick is used for image resizing and processing
gem "rmagick", ">= 2.12.2", :require => 'RMagick', :platforms => :ruby

# Attachable does all the file work.
gem 'attachable', '>= 0.0.5'

gem 'devise', '~> 3.0.0'
gem 'cancan'

gem 'json', '1.7.7'

# Process jobs in the background
gem 'foreman', :group => :development
gem 'delayed_job_active_record'
gem 'clockwork'

# Test Coverage
gem 'simplecov', :require => false, :group => :test

gem 'strong_parameters'

gem 'kaminari', '>= 0.14.1'  # Pagination

# Enable the newsfeed for 1.9+ users.
gem 'public_activity', :platforms => [:ruby_19, :ruby_20]

gem 'RedCloth'
gem 'docsplit'   # for graphics and pdf, ppt conversion

