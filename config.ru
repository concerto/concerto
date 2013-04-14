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
  if command?('gem') == false && command?('bundle') == false
    raise "Gem and Bundler are required to run Concerto gem installation"
  end
  
  #get output of the bundle install command for later possible use
  bundle_output = `bundle install`
  #use the magical object from $? to get status of output
  result = $?.success?
  
  #if the command doesn't work, retrieve the backup Gemfile and restart
  if !result
    old_gemfile = IO.read("Gemfile-plugins.bak")
    File.open("Gemfile-plugins", 'w') {|f| f.write(old_gemfile) }
    restart_webserver()
  end

end

require ::File.expand_path('../config/environment',  __FILE__)
run Concerto::Application
