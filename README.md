#Concerto 2 Digital Signage System

##Automated Installation:
APT(Debian/Ubuntu) Package:
Add Concerto repository using: curl https://get.concerto-signage.org/add_repo.sh | sh

Install Concerto via APT: sudo apt-get install concerto

Generic Linux/Mac: curl https://get.concerto-signage.org | ruby

Generic Linux/Mac with MySQL: Download https://get.concerto-signage.org/install.rb and run it like this: "ruby install.rb -d mysql"

Windows: Download https://get.concerto-signage.org/install.rb and run it

OR

##Manual Installation:
NB: Upon startup, Concerto will create and configure a SQLite database. If you wish to alter this, edit config/database.yml appropriately. 
A sample MySQL database configuration file is provided in config/database.yml.mysql - it can replace config/database.yml when edited.
Upon its next startup, Concerto will populate whatever database you've specified.

1. git clone https://github.com/concerto/concerto.git
2. cd concerto
3. bundle install or bundle install --path vendor/bundle if you don't wish to install all of the Gem dependencies of Concerto/Rails globally (there are just over 115 of them).
4. Set up the appropriate webserver configuration (VHosts and such) and start using Concerto
5. Go the the Concerto URL to setup the initial admin user.

##
Installation Notes:
When running Concerto in production mode, be sure to compile your assets with: bundle exec rake assets:precompile or Sprockets will be used as a fallback, with performance consequences.

Concerto 2 is licensed under the Apache License, Version 2.0.
