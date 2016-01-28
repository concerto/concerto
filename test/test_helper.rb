require 'simplecov'

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
include Devise::TestHelpers
load "#{Rails.root}/config/initializers/02-concerto_config.rb"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all
  
  # Add more helper methods to be used by all tests here...
  def assert_login_failure
    assert_redirected_to root_url
    assert flash[:notice]
    assert flash[:notice].include? 'not authorized'
  end

  def assert_small_delta(expected, actual)
    assert_in_delta(expected, actual, 0.00001)
  end

end