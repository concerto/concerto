# Concerto 2 Digital Signage System [![Build Status](https://travis-ci.org/concerto/concerto.png?branch=master)](https://travis-ci.org/concerto/concerto)

[![Join the chat at https://gitter.im/concerto/concerto](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/concerto/concerto?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Full Installation Instructions: [https://github.com/concerto/concerto/wiki/Installing-Concerto-2](https://github.com/concerto/concerto/wiki/Installing-Concerto-2)

## What is Concerto?
Concerto is an open source digital signage system. Users submit graphic, textual, and other content, and moderators approve that content for use in a variety of content feeds which are displayed on screens connected to computers displaying the Concerto frontend.

## Dependencies
* Ruby 2.0 or newer
* Rubygems
* Imagemagick
* Webserver (Apache/Unicorn/Thin/Nginx)
* Rack interface to the webserver (Passenger, FastCGI)
* ActiveRecord-compatible database (Mysql, SQLite, Postgres)

## Debian Package Installation
Note: For those upgrading Concerto from earlier Debian/Ubuntu versions, make sure that your APT source line looks like this: http://dl.concerto-signage.org/packages/ stretch main

* Add Concerto repository using ```curl https://get.concerto-signage.org/add_repo.sh | sh```
* Install Concerto via APT ```sudo apt-get install concerto-full```

## Virtual Server Image (VirtualBox, VMWare, et. al.)
The virtual server image contains a full-stack installation of the Concerto webserver with all components pre-configured.

* Download at [https://dl.concerto-signage.org/concerto_server.ova](https://dl.concerto-signage.org/concerto_server.ova)

Concerto 2 is licensed under the Apache License, Version 2.0.
