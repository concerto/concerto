# Edit this Gemfile to bundle your application's dependencies.
source 'https://rubygems.org'

gem "rails", "~> 3.2.17"

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

# Load a local Gemfile if it exists
if File.exists?(basedir+'/Gemfile.local')
  eval File.read(basedir+'/Gemfile.local')
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'therubyracer', :platforms => :ruby
  gem 'execjs'
  gem 'uglifier'
end

gem 'jquery-rails'
gem 'turbolinks'
gem 'jquery-timepicker-rails'
gem 'bootstrap-datepicker-rails'
gem 'twitter-bootstrap-rails-confirm'

#RMagick is used for image resizing and processing
gem "rmagick", :require => 'RMagick', :platforms => :ruby

# Attachable does all the file work.
gem 'attachable'

gem 'devise', '~> 3.0.0'
gem 'cancancan'

gem 'json'
gem "rubyzip", '< 1.0.0'

# Process jobs in the background
gem 'foreman', :group => :development
gem 'delayed_job_active_record'
gem 'clockwork'

# Test Coverage
gem 'simplecov', :require => false, :group => :test

gem 'strong_parameters'

gem 'kaminari'

require "#{Dir.getwd}/lib/command_check.rb"
if system_has_mysql?
  mysql_platforms = Bundler::Dependency::PLATFORM_MAP.keys
else
  mysql_platforms = [:mswin]
end
if system_has_postgres?
  postgres_platforms = Bundler::Dependency::PLATFORM_MAP.keys
else
  postgres_platforms = [:mswin]
end

# In production we prefer MySQL over sqlite3.  If you are only
# interested in development and don't want to bother with production,
# run `bundle install --without production` to ignore MySQL.
gem "sqlite3", :group => [:development, :test]

gem "mysql2", :require => false, :group => :production, :platforms => mysql_platforms
gem "pg", :require => false, :group => :production, :platforms => postgres_platforms

gem 'public_activity'

gem 'redcarpet'
gem 'concerto_docsplit'

# NProgress provides progress bars for pages loaded via Turbolinks
gem 'nprogress-rails', '~> 0.1.3.0'

gem 'i18n-tasks', '~> 0.4.5', :group => :development
