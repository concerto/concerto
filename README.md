#Concerto 2 Digital Signage System

Dependencies: Ruby, Gem, Imagemagick, a webserver (Apache/Unicorn/Thin/Nginx), a Rack interface to the webserver (Passenger, FastCGI), a relational database (Mysql, SQLite, Postgres)

##APT(Debian/Ubuntu) Full Concerto Package:
The full concerto package will closely replicate the setup of the server virtual image. It includes Imagemagick, Ruby 1.9, the MySQL client libraries, Apache2, and all the required libraries for Passenger (though Passenger itself will be installed outside of Debian (as the repository version is generally horribly outdated). 

* Add Concerto repository using ```curl https://get.concerto-signage.org/add_repo.sh | sh```
* Install Concerto via APT ```sudo apt-get install concerto-full```
    
##APT(Debian/Ubuntu) Lite Concerto Package:
The more lightweight Concerto package will make relatively few assumptions about a system's setup. It requires ImageMagick, Ruby 1.9, the MySQL client libraries and the associated ruby bindings.

* Add Concerto repository using ```curl https://get.concerto-signage.org/add_repo.sh | sh```
* Install Concerto via APT ```sudo apt-get install concerto-lite```

##Virtual Server Image (VirtualBox, VMWare, et. al.)
The virtual server image contains a full-stack installation of the Concerto webserver with all components pre-configured.
* Download http://dl.concerto-signage.org/concerto_server.ova
* Load it into your VM tool of choice
* Login using the credentials in the OVA file comments and follow the initial configuration scripts - which will set a proper root password and proper database credentials for Concerto (using randomized passwords).
* Make any network-specific changes to /etc/apache2/sites-available/concerto and restart Apache if needed

##Installation Script
The install.rb script will install Concerto from source, optionally configure a MySQL database, show a sample Apache configuration, and run a bundle install (with the ```--path=vendor/bundle``` option to avoid interfering with system-wide gem installations).

* Generic Linux/Mac: ```curl https://get.concerto-signage.org | ruby```
* Generic Linux/Mac with MySQL: Download https://get.concerto-signage.org/install.rb and run it like this: ```ruby install.rb -d mysql```
* Windows: Download https://get.concerto-signage.org/install.rb and run it

##Manual Installation:
NB: Upon startup, Concerto will create and configure a SQLite database (or a MySQL one if in production). If you wish to alter this, edit config/database.yml appropriately. 
A sample MySQL database configuration file is provided in config/database.yml.mysql - it can replace config/database.yml when edited.
Upon its next startup, Concerto will populate whatever database you've specified.

1. ```git clone https://github.com/concerto/concerto.git```
2. ```cd concerto```
3. ```bundle install``` or ```bundle install --path vendor/bundle``` if you don't wish to install all of the Gem dependencies of Concerto/Rails globally (there are just over 115 of them).
4. Set up the appropriate webserver configuration (VHosts and such) and start using Concerto
5. Go the the Concerto URL to setup the initial admin user.

Concerto 2 is licensed under the Apache License, Version 2.0.
