# This file is used by Rack-based servers to start the application.

#Cross-platform way of finding an executable in the $PATH
#which('ruby') #=> /usr/bin/ruby
#Courtesy of Mislav Marohnic (via Stackoverflow)
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = "#{path}/#{cmd}#{ext}"
      return exe if File.executable? exe
    }
  end
  return nil
end

#Check for existence of a command for use
def command?(command)
  if which(command) != nil
    return true
  else
    return false
  end
end

#load low-level config yaml to check installation config params
require 'yaml'
concerto_base_config = YAML.load_file("./config/concerto.yml")

if concerto_base_config['automatic_bundle_installation'] == true
  #if gem isn't present, sod-all. But if gem is there and bundler isn't - attempt the installation
  if command?('gem')
    if command?('bundle')
      system("bundle install --path=vendor/bundle")
    else
      system("gem install bundler")
      system("bundle install --path=vendor/bundle")
    end
  end
end

require ::File.expand_path('../config/environment',  __FILE__)
run Concerto::Application
