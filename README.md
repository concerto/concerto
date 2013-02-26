#Concerto 2 Digital Signage System
Full Installation Instructions: https://github.com/concerto/concerto/wiki/Installing-Concerto-2

##What is Concerto?

##Dependencies
Ruby, Gem, Imagemagick, a webserver (Apache/Unicorn/Thin/Nginx), a Rack interface to the webserver (Passenger, FastCGI), a relational database (Mysql, SQLite, Postgres)

## Debian Package Installation
* Add Concerto repository using ```curl https://get.concerto-signage.org/add_repo.sh | sh```
* Install Concerto via APT ```sudo apt-get install concerto-full```
    
##Virtual Server Image (VirtualBox, VMWare, et. al.)
The virtual server image contains a full-stack installation of the Concerto webserver with all components pre-configured.
* Download at http://dl.concerto-signage.org/concerto_server.ova

Concerto 2 is licensed under the Apache License, Version 2.0.
