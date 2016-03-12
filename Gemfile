# Edit this Gemfile to bundle your application's dependencies.
source 'https://rubygems.org'

gem 'rails', '~> 4.2.5'

# Get the absolute path of this Gemfile so the includes below still work
# when the current directory for a bundler command isn't the application's
# root directory.
basedir = File.dirname(__FILE__)

# Load the gems used for remote reporting.
if File.exists?("#{basedir}/Gemfile-reporting")
  eval File.read("#{basedir}/Gemfile-reporting")
end

# The Gemfile-plugins gem list is managed by Concerto itself,
# through the ConcertoPlugins controller.
group :concerto_plugins do
  eval File.read("#{basedir}/Gemfile-plugins") if File.exists?("#{basedir}/Gemfile-plugins")
end

# Load a local Gemfile if it exists
if File.exists?("#{basedir}/Gemfile.local")
  eval File.read("#{basedir}/Gemfile.local")
end

gem 'sass-rails'
gem 'sprockets', '~> 2.11.3'
gem 'therubyracer', platforms: :ruby
gem 'execjs', '~> 2.2.2'
gem 'uglifier', '~> 2.7.2'

gem 'jquery-rails'
gem 'turbolinks'
gem 'jquery-timepicker-rails'
gem 'bootstrap-datepicker-rails'
gem 'twitter-bootstrap-rails-confirm'

gem 'responders', '~> 2.0'

#RMagick is used for image resizing and processing
gem 'rmagick', require: 'rmagick', platforms: :ruby

# Attachable does all the file work.
gem 'attachable'

gem 'devise', '~> 3.5.5'
gem 'cancancan'

gem 'json'
gem 'rubyzip', '~> 1.1.6'

# Process jobs in the background
gem 'foreman', group: :development
gem 'delayed_job_active_record'
gem 'clockwork'

group :test do
  gem 'bundler-audit', require: false, group: :test
  gem 'codeclimate-test-reporter', group: :test, require: nil
end

gem 'kaminari'

gem 'pg'

gem 'public_activity'

gem 'redcarpet', '~> 3.3.2'
gem 'concerto_docsplit'

# NProgress provides progress bars for pages loaded via Turbolinks
gem 'nprogress-rails', '~> 0.1.6.3'
gem 'google-analytics-turbolinks', '~> 0.0.4'

# I18n Tasks
group :development do
  gem 'i18n-tasks', '0.9.0'
  gem 'slop', '~> 3.6.0' # Required due to https://github.com/glebm/i18n-tasks/issues/118
end

gem 'i18n-js', '>= 3.0.0.rc8', '< 3.1.0'

#Github API
gem 'octokit', '~>4.2.0'

gem 'font-awesome-sass'

# Web console
gem 'web-console', '~> 2.0', group: :development
