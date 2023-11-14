# Edit this Gemfile to bundle your application's dependencies.
source 'https://rubygems.org'

# Lock the ruby version for now. We don't work on Ruby 2.7, so stick with Ruby 2.6
ruby '~> 2.6.0'

gem 'rails', '~> 5.0.7', '>= 5.0.7.2'
gem 'nokogiri', '~> 1.13', '>= 1.13.10' #pin while on ruby < 2.7

# Get the absolute path of this Gemfile so the includes below still work
# when the current directory for a bundler command isn't the application's
# root directory.
basedir = File.dirname(__FILE__)

# The Gemfile-plugins gem list is managed by Concerto itself,
# through the ConcertoPlugins controller.
group :concerto_plugins do
  eval File.read("#{basedir}/Gemfile-plugins") if File.exist?("#{basedir}/Gemfile-plugins")
end

# Load a local Gemfile if it exists
if File.exist?("#{basedir}/Gemfile.local")
  eval File.read("#{basedir}/Gemfile.local")
end

gem 'coffee-rails'
gem 'execjs'
gem 'sass-rails'
gem 'sprockets'
# use nodejs instead of therubyracer for js engine for easier docker and future work
#gem 'therubyracer', platforms: :ruby
gem 'uglifier'
gem 'mime-types'

gem 'bootstrap-datepicker-rails'
gem 'jquery-rails'
gem 'jquery-timepicker-rails'
gem 'turbolinks', '~>2.5.3'
gem 'twitter-bootstrap-rails-confirm'

gem 'responders'

# RMagick is used for image resizing and processing
gem 'rmagick', require: 'rmagick', platforms: :ruby

# Attachable does all the file work.
gem 'attachable'

gem 'cancancan'
gem 'devise'

gem 'json'
gem 'rubyzip', '~> 1.3.0'

# Process jobs in the background
gem 'clockwork'
gem 'delayed_job_active_record'
gem 'foreman', group: :development

# Test Coverage
gem 'simplecov', require: false, group: :test

# Gem Auditing
gem 'bundler-audit', require: false, group: :test

gem 'rails-controller-testing'

gem 'kaminari'

gem 'sqlite3', '~> 1.3.6', group: [:development, :test]

gem 'mysql2', group: :mysql
gem 'pg', '~> 0.18', group: :postgres

gem 'public_activity'

gem 'concerto_docsplit'
gem 'redcarpet', '~> 3.5.1'

gem 'google-analytics-turbolinks', '~> 0.0.4'

# NProgress provides progress bars for pages loaded via Turbolinks
gem 'nprogress-rails', '~> 0.2.0.2'

# I18n Tasks
group :development do
  gem 'i18n-tasks'
  gem 'slop', '~> 3.6.0' # Required due to https://github.com/glebm/i18n-tasks/issues/118
  gem 'awesome_print'
  gem 'rack-mini-profiler'
end

gem 'i18n-js', '>= 3.0.0.rc8', '< 3.1.0'

# Github API
gem 'octokit', '~>4.2.0'

gem 'font-awesome-sass'

# Web console
gem 'web-console', group: :development
