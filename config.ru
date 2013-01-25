# This file is used by Rack-based servers to start the application.
require 'yaml'
concerto_base_config = YAML.load_file("./config/concerto.yml")
if concerto_base_config['automatic_bundle_installation'] == true
  system("bundle install --path=vendor/bundle")
end
require ::File.expand_path('../config/environment',  __FILE__)
run Concerto::Application
