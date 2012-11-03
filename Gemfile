# Edit this Gemfile to bundle your application's dependencies.
source 'http://rubygems.org'

gem "rails", "3.2.8"

# Load the gems used for remote reporting.
eval File.read('Gemfile-reporting')

group :concerto_plugins do
  eval File.read('Gemfile-plugins')
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.2.3"
  gem 'coffee-rails', "~> 3.2.1"

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# In production we prefer MySQL over sqlite3.  If you are only
# interested in development and don't want to bother with production,
# run `bundle install --without production` to ignore MySQL.
gem "sqlite3", :group => [:development, :test]
gem "mysql2", :group => [:production]

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

#RMagick is used for image resizing and processing
gem "rmagick", ">= 2.12.2", :require => 'RMagick'

# Attachable does all the file work.
gem 'attachable', '>= 0.0.5'

gem 'devise'
gem 'cancan'

gem 'jquery-tools'

# Process jobs in the background
gem 'delayed_job_active_record'
gem "daemons"

# Test Coverage
gem 'simplecov', :require => false, :group => :test

#Cross-platform monitoring of processes
gem 'sys-proctable'
