# Edit this Gemfile to bundle your application's dependencies.
source 'https://rubygems.org'

# the ruby version is specified in the Gemfile, the Dockerfile, and the nginx.docker.conf files
ruby '2.4.6'

gem 'rails', '~> 4.2'

# Get the absolute path of this Gemfile so the includes below still work
# when the current directory for a bundler command isn't the application's
# root directory.
basedir = File.dirname(__FILE__)

# Load the gems used for remote reporting.
if File.exist?("#{basedir}/Gemfile-reporting")
  eval File.read("#{basedir}/Gemfile-reporting")
end

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
gem 'execjs', '~> 2.2.2'
gem 'sass-rails'
gem 'sprockets', '~> 2.11.3'
# use nodejs
#gem 'therubyracer', platforms: :ruby
gem 'uglifier', '~> 2.7.2'

gem 'bootstrap-datepicker-rails'
gem 'jquery-rails'
gem 'jquery-timepicker-rails'
gem 'turbolinks', '~>2.5.3'
gem 'twitter-bootstrap-rails-confirm'

gem 'responders', '~> 2.0'

# RMagick is used for image resizing and processing
gem 'rmagick', require: 'rmagick', platforms: :ruby

# Attachable does all the file work.
gem 'attachable'

gem 'cancancan'
gem 'devise', :git=> "https://github.com/plataformatec/devise.git", :branch => "3-stable"

gem 'json'
gem 'rubyzip', '~> 1.2.1'

# Process jobs in the background
gem 'clockwork'
gem 'delayed_job_active_record'
gem 'foreman', group: :development

# Test Coverage
gem 'simplecov', require: false, group: :test

# Gem Auditing
gem 'bundler-audit', require: false, group: :test

gem 'kaminari'

gem 'sqlite3', group: [:development, :test]

gem 'mysql2', group: :mysql
gem 'pg', group: :postgres

gem 'public_activity'

gem 'concerto_docsplit'
gem 'redcarpet', '~> 3.3.2'

gem 'google-analytics-turbolinks', '~> 0.0.4'

# NProgress provides progress bars for pages loaded via Turbolinks
gem 'nprogress-rails', '~> 0.2.0.2'

# I18n Tasks
group :development do
  gem 'i18n-tasks', '0.9.0'
  gem 'slop', '~> 3.6.0' # Required due to https://github.com/glebm/i18n-tasks/issues/118
end

gem 'i18n-js', '>= 3.0.0.rc8', '< 3.1.0'

# Github API
gem 'octokit', '~>4.2.0'

gem 'font-awesome-sass'

# Web console
gem 'web-console', '~> 2.0', group: :development
