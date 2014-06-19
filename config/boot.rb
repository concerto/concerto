# This file is called in several entry points to the application.
# It loads the gems from the Bundle. For the purposes of Concerto's
# plugin installation, we have inserted code to check for gems that
# need to be installed (for example new plugins), and automatically
# run bundle install. It is our goal for all entry points to the app
# come through here before loading Bundler.
# Supported:
#   script/rails commands (such as launching the built-in server)
#   Passenger web servers configured as a Rack app
#       See config/setup_load_paths.rb
#   Standard rack servers that just load config.ru
# Not supported
#   bundle exec commands (bundle exec rails server, for example)

# The auto-install behavior can be disabled in config/concerto.yml.

require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

# >>> Concerto-specific modifications ahead. <<<

# Include "which" and "command?" methods:
require File.expand_path('../../lib/command_check.rb', __FILE__)

#load low-level config yaml to check installation config params
require 'yaml'
concerto_base_config = YAML.load_file("./config/concerto.yml")
if File.exists?('.bundle/config')
  bundle_config = YAML.load_file('.bundle/config')
  #If this bundle variable is set, bundler has been used with the --deployment option
  #This option forbids any difference between the Gemfile and Gemfile.lock
  #and causes dynamic plugin installation to break Concerto
  if bundle_config['BUNDLE_FROZEN'] == "1"
    ENV['FROZEN'] = "1"
  end
end
#To do automagical bundle installation, frozen gems must NOT be in use,
#the eponymous option must be set in concerto.yml,
#and Concerto cannot be running in the test environment (or at least not Travis')
if ENV['FROZEN'] != "1" && concerto_base_config['automatic_bundle_installation'] == true && ENV['RAILS_ENV'] != 'test'
  if command?('gem') == false && command?('bundle') == false
    raise "Gem and Bundler are required to run Concerto gem installation.\n" +
    	  "You can disable automatic gem installation in config/concerto.yml"
  end

  #get output of the bundle install command for later possible use
  bundle_output = `bundle install #{concerto_base_config['bundle_install_options']}`
  #use the magical object from $? to get status of output
  result = $?.success?

  #if the command doesn't work, retrieve the backup Gemfile and restart
  if !result
    if File.file? "Gemfile-plugins.bak"
      old_gemfile = IO.read("Gemfile-plugins.bak")
      File.open("Gemfile-plugins", 'w') {|f| f.write(old_gemfile) }
    end
    raise "Bundler error: #{bundle_output}"
  end
end

# >>> End of concerto-specific mods. Proceed with booting app. <<<

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
