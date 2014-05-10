#Concerto 2 Digital Signage System 

Forked to use CAS Authentication for deployment at RPI.

Full Installation Instructions: [https://github.com/concerto/concerto/wiki/Installing-Concerto-2](http://goo.gl/4YIzK)

##What is Concerto?
Concerto 2 represents the latest and greatest in connected digital ecosystems.

##Dependencies
* Ruby
* Gem
* Imagemagick
* Webserver (Apache/Unicorn/Thin/Nginx)
* Rack interface to the webserver (Passenger, FastCGI)
* ActiveRecord-compatible database (Mysql, SQLite, Postgres)

## Debian Package Installation
* Add Concerto repository using ```curl https://get.concerto-signage.org/add_repo.sh | sh```
* Install Concerto via APT ```sudo apt-get install concerto-full```
    
##Virtual Server Image (VirtualBox, VMWare, et. al.)
The virtual server image contains a full-stack installation of the Concerto webserver with all components pre-configured.

* Download at [https://dl.concerto-signage.org/concerto_server.ova](https://dl.concerto-signage.org/concerto_server.ova)

Concerto 2 is licensed under the Apache License, Version 2.0.