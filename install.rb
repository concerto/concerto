#!/usr/bin/env ruby
#A script for bootstrapping Concerto so the installation scripts can do their work
#Parameters: 
  #concerto_location
  #concerto_hostname
  #database_type

def main
  parse_options()
  
  #Check that package dependencies are installed. If not, we're just going to tell the user (as they might not be using Debian et al.)
  check_pkg_depends()
  
  #Retrieve Concerto source/zip from Github 
  if command?("git")
    puts "Cloning Git repository..."
    system("git clone https://github.com/concerto/concerto.git #{$concerto_location}")
  else
    puts "Git executable not found -- downloading tarball..."
    system("wget -O /tmp/concerto.tar.gz https://github.com/concerto/concerto/tarball/master")
    system("tar -zxvf /tmp/concerto.tar.gz #{$concerto_location}")
  end
  
  Dir.chdir($concerto_location) do
    #Install gems
    puts "Installing Gems..."
    system("bundle install --path vendor/bundle;")
    
    if $database_type.nil?
      #Copy over default database.yml for dong default sqlite
      system("cp config/database.yml.sample config/database.yml")
    end
    
    #Migrate database and install seed data
    puts "Migrating Database and Installing Seed Data..."
    system("rake db:setup")
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
    puts "Concerto is being installed to /var/www/concerto. To specify the location to deploy Concerto to, use the -l option"
    $concerto_location = "/var/www/concerto" 
  end
end

def mysql_config
  #replace sqliite with mysql
  system("sed -i 's/sqlite3/mysql2/g' /usr/share/concerto/Gemfile")
  
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

#Check for existence of a command for use (and send the output to the bitbucket)
def command?(command)
  system("which #{ command} > /dev/null 2>&1")
end

def generate_password(len)
  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  newpass = ""
  1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
  return newpass
end

def package?(package_name)
  #grep through the output of dpkg -s to see if a package status is given. If so, we assume it's installed and working
  if system("dpkg -s #{pkg} | grep Status") != true
    return false
  else
    return true
  end
end

def check_pkg_depends
  #Concerto imagemagick package dependencies
  pkg_depends = ['imagemagick', 'librmagick-ruby', 'libmagickcore-dev', 'libmagickwand-dev']
  #Add additional MySQL package requirements (if -d mysql is invoked)
  if $database_type == "mysql"
    pkg_depends << "mysql-server" << "mysql-client" << "libmysql-ruby1.9.1"
  end
  #all unmet dependencies will be pushed onto this array
  unmet_depends.new
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

main()
