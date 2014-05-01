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
#turn off SSL verification stuff due to Ruby bug (mostly a Windows issue)
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  
def main
  parse_options()
  
  if $database_type.nil? == false && Kernel.is_windows?
    puts "Only SQLite Database autoconfiguration is available on Windows"
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
    system("git checkout #{get_tag()}")
  else
    puts "Git executable not found -- downloading zip/tar file..."
    #Zip files are a sensible default for Windows
    if Kernel.is_windows?
      windows_download()
    else
      #Virtually all *nix systems have tar
      download_file("https://github.com/concerto/concerto/archive/#{get_tag()}.tar.gz", "/tmp/concerto.tar.gz")
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
    
    system("bundle install --path vendor/bundle") 
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

def get_tag()
  require 'net/https'
  require 'uri'
  require 'json'
  
  uri = URI.parse('https://api.github.com/repos/concerto/concerto/git/refs/tags')
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.scheme == "https" # enable SSL/TLS
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ca_file = File.join("cacert.pem")
  end
  http.start {
    http.request_get(uri.path) {|res|
      @versions = Array.new
      JSON.parse(res.body).each do |tag|
        @versions << tag['ref'].gsub(/refs\/tags\//,'')
      end
      @versions.sort! {|x,y| y <=> x }
      return @versions[0]
    }
  }
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
      puts "Concerto is being installed to c:\concerto. To specify the location to deploy Concerto to, use the -l option"
      $concerto_location = 'c:\concerto'
    else
      puts "Concerto is being installed to /var/www/concerto. To specify the location to deploy Concerto to, use the -l option"
      $concerto_location = "/var/www/concerto" 
    end
  end
end

#This is a *nix-only method for getting MySQL configured for Concerto
def mysql_config 
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

def windows_download
  #get the full path to the user's temp directory and chop off the newline
  user_tempdir = `echo %TEMP%`.chomp
  #download the Github zipball (and do some acrobatics b/c Github doesn't know how to package a zip)
  download_file("https://github.com/concerto/concerto/archive/#{get_tag()}.zip", "#{user_tempdir}\\concerto.zip") 
  #Windows has no unzip executable - so let's download a a nice standalone one
  download_file("http://stahlworks.com/dev/unzip.exe", "#{user_tempdir}\\unzip.exe")
  #unzip the concerto archive from Github into the temp directory
  system("%temp%\\unzip.exe %temp%\\concerto.zip -d %temp%\\concerto")
  #Now the tricky part: github packs a folder appended with the commit id into the root of the zip
  #-which makes unarchiving tricky on a non-Debian system (Debian provides the pathname param to deal with this)
  #Move the only directory in temp/concerto to c:\concerto (or whatever location)
  system("for /D %j in (%temp%\\concerto\\*) do move %j #{windows_path($concerto_location)}")
  #Be neat - clean up all temp files and folders used
  `del /q /s %temp%\\unzip.exe %temp%\\concerto.zip`
  `rmdir /q /s %temp%\\concerto`
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

#take a normal *nix path and return a properly escaped Windows one
def windows_path(nix_path)
  nix_path.gsub('/', '\\')
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
  if system("dpkg -s #{package_name} | grep Status") != true
    return false
  else
    return true
  end
end

def check_deb_pkg_depends
  #Concerto imagemagick package dependencies
  pkg_depends = ['imagemagick', 'ruby-rmagick', 'libmagickcore-dev', 'libmagickwand-dev']
  #Add additional MySQL package requirements (if -d mysql is invoked)
  if $database_type == "mysql"
    pkg_depends << "mysql-server" << "mysql-client" << "ruby-mysql"
  end
  #all unmet dependencies will be pushed onto this array
  unmet_depends = Array.new
  pkg_depends.each do |package_name|
    if package?(package_name) != true
      unmet_depends << package_name
    end
  end
  
  #Warn the user about unmet dependencies
  unless unmet_depends.empty?
    puts "Dependencies not met! Concerto requires the packages: #{unmet_depends.each {|d| print d, ", " } }"
  end
end

# Returns true if we are running on a MS windows platform, false otherwise.
#Don't know where the mingw32 signature came along - but it's needed
def Kernel.is_windows?
  processor, platform, *rest = RUBY_PLATFORM.split("-")
  platform == 'mswin32' || platform == 'mingw32'
end

#download given file to specified destination using open-uri
def download_file(file_url, file_destination) 
  File.open(file_destination, "wb") do |saved_file|
    # the following "open" is provided by open-uri
    open(file_url) do |read_file|
      saved_file.write(read_file.read)
    end
  end
end

main()
