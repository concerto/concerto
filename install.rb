#!/usr/bin/env ruby
#A script for bootstrapping Concerto so the installation scripts can do their work
#Parameters: 
  #concerto_location
  #concerto_hostname
  #database_type
  
#used for platform-agnostic downloading of zip and tar files  
require 'open-uri'
#used for platform-agnostic file copying
require 'fileutils'
  
def main
  parse_options()
  
  if $database_type.nil? == false && Kernel.is_windows?
    puts "Non-sqlite database autoconfiguration is not available on Windows"
    exit
  end
  
  #Check that package dependencies are installed. If not, try some other detection strategies
  if command?("apt-get")
    check_deb_pkg_depends()
  else
    check_general_depends()
  end  
    
  #Retrieve Concerto source/tar/zip from Github 
  if command?("git")
    puts "Cloning Git repository..."
    system("git clone https://github.com/concerto/concerto.git #{$concerto_location}")
  else
    puts "Git executable not found -- downloading non-git file..."
    #Zip files are a sensible default for Windows
    if Kernel.is_windows?
      download_file("https://github.com/concerto/concerto/zipball/master", "c:\\concerto.zip") 
      download_file("http://stahlworks.com/dev/unzip.exe", "c:\\unzip.exe")
      system("c:\\unzip.exe c:\\concerto.zip #{$concerto_location}")  
      system("del c:\\unzip.exe c:\\concerto.zip")
    else
      #Virtually all *nix systems have tar
      download_file("https://github.com/concerto/concertoo/tarball/master", "/tmp/concerto.tar.gz")
      system("tar -zxvf /tmp/concerto.tar.gz #{$concerto_location}")
    end
  end
    
  Dir.chdir($concerto_location) do
    #Install gems
    puts "Installing Gems..."
    unless command?("bundle")
      puts "Bundler is not installed. Please install the bundler gem with gem install bundler"
      exit
    end
    
    system("bundle install --path /vendor/bundle")
    
    if $database_type.nil?
      #Copy over default database.yml for dong default sqlite
      FileUtils.cp "/config/database.yml.sample", "/config/database.yml"
    end
    
    #Migrate database and install seed data
    puts "Migrating Database and Installing Seed Data..."
    if command?("rake") != true
      bundle_rake = system("bundle exec rake db:setup")
      if bundle_rake != true
        puts "The rake gem is not installed globally or in the local bundle. Run gem install rake"
        exit
      end
    else
      system("rake db:setup")
    end 
  end
  
  #Create Apache VHost entry with interpolated values
  vhost_entry = %{<VirtualHost *:80>
    ServerName #{$concerto_hostname || "<SERVER HOSTNAME HERE>"}
    DocumentRoot "#{$concerto_location}"
    RailsEnv production
    <Directory "#{$concerto_location}">
      Order allow,deny
      Allow from all
    </Directory>
  </VirtualHost>}
  puts "Please add the following to your Apache configuration file and restart Apache...\n\n"
  puts vhost_entry

end

#Parse command line options with some Ruby magicks
def parse_options
  require 'optparse'
  OptionParser.new do |o|
    o.on("-d database_type") { |d| $database_type = d }
    o.on("-n concerto_hostname") { |n| $concerto_hostname = n }
    o.on('-l concerto_location') { |location| $concerto_location = location }
    o.on("-h", "--help", "Show this message") { puts o; exit }
    o.parse!
  end
  #A sensible default for Concerto installation location
  if $concerto_location.nil?
    if Kernel.is_windows?
      $concerto_location = "c:\\concerto"
    else
      puts "Concerto is being installed to /var/www/concerto. To specify the location to deploy Concerto to, use the -l option"
      $concerto_location = "/var/www/concerto" 
    end
  end
end

def mysql_config
  #replace sqliite with mysql
  system("sed -i 's/sqlite3/mysql2/g' #{$concerto_location}/Gemfile")
  
  #turn of terminal echo so the password isn't seen
  `stty -echo`
  print "Enter MySQL root password: "
  password = gets.chomp
  `stty echo`
  puts ""
  
  puts "A random password is now being generated for use in Concerto's database configuration"
  random_password = generate_password(12)
  query = "create database concerto;GRANT ALL ON concerto.* to concerto@'localhost' IDENTIFIED BY '#{random_password}';flush privileges;"
  system("mysql -u root -p#{password} -e \"#{query}\"")

  database_yml = %{development:
adapter: mysql2
database: concerto
username: concerto
password: #{random_password}
host: localhost

production:
adapter: mysql2
database: concerto
username: concerto
password: #{random_password}
host: localhost}

  #write new YAML to database config file in concerto
  File.open("#{$concerto_location}/config/database.yml", 'w') {|f| f.write(database_yml) }

end

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

def generate_password(len)
  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  newpass = ""
  1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
  return newpass
end

def check_general_depends
  unmet_depends = Array.new
  
  unless command?("convert")
    unmet_depends << "ImageMagick is not properly installed or is not in the PATH.\n"
  end
   
  if $database_type == "mysql"
    unless command?("mysql")
      unmet_depends << "MySQL Client is not properly installed or is not in the PATH.\n"
    end
    unless command?("mysqld")
      unmet_depends << "MySQL daemon is not properly installed or is not in the PATH.\n"
    end    
  end
  
  #Warn the user about unmet dependencies
  unless unmet_depends.empty?
    unmet_depends.each {|d| print d}
  end  
end

def package?(package_name)
  #grep through the output of dpkg -s to see if a package status is given. If so, we assume it's installed and working
  if system("dpkg -s #{pkg} | grep Status") != true
    return false
  else
    return true
  end
end

def check_deb_pkg_depends
  #Concerto imagemagick package dependencies
  pkg_depends = ['imagemagick', 'librmagick-ruby', 'libmagickcore-dev', 'libmagickwand-dev']
  #Add additional MySQL package requirements (if -d mysql is invoked)
  if $database_type == "mysql"
    pkg_depends << "mysql-server" << "mysql-client" << "libmysql-ruby1.9.1"
  end
  #all unmet dependencies will be pushed onto this array
  unmet_depends = Array.new
  pkg_depends.each do |package_name|
    if package(package_name) != true
      unmet_depends << package_name
    end
  end
  
  #Warn the user about unmet dependencies
  unless unmet_depends.empty?
    puts "Dependencies not met! Concerto requires the packages: #{unmet_depends.each {|d| print d, ", " } }"
  end
end

# Returns true if we are running on a MS windows platform, false otherwise.
def Kernel.is_windows?
  processor, platform, *rest = RUBY_PLATFORM.split("-")
  platform == 'mswin32' || platform == 'mingw32'
end

#download given file to0 specified destination using open-uri
def download_file(file_url, file_destination) 
  File.open(file_destination, "wb") do |saved_file|
    # the following "open" is provided by open-uri
    open(file_url) do |read_file|
      saved_file.write(read_file.read)
    end
  end
end

main()
