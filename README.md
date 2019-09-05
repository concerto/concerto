# Concerto 2 Digital Signage System [![Build Status](https://travis-ci.org/concerto/concerto.png?branch=master)](https://travis-ci.org/concerto/concerto)

[![Join the chat at https://gitter.im/concerto/concerto](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/concerto/concerto?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Full Installation Instructions: [https://github.com/concerto/concerto/wiki/Installing-Concerto-2](https://github.com/concerto/concerto/wiki/Installing-Concerto-2)

## What is Concerto?

Concerto is an open source digital signage system. Users submit graphic, textual, and other content, and moderators approve that content for use in a variety of content feeds which are displayed on screens connected to computers displaying the Concerto frontend.

## Dependencies

* Ruby 2.3.8 or newer
* Rubygems
* Imagemagick, GhostScript, Poppler-Utils
* LibreOffice
* Webserver (Apache/Unicorn/Thin/Nginx)
* Rack interface to the webserver (Passenger, FastCGI)
* ActiveRecord-compatible database (Mysql, SQLite, Postgres)
* Nodejs as the javascript engine (as of version 2.3.7)

## Docker Image

To build and run the docker image locally, (make sure you don't already have port 80 in use):

```
1. git clone http://github.com/concerto/concerto
2. cd concerto
3. bundle install
4. docker build -t concerto .
5. docker-compose up
```

To get into the concerto container: `docker exec -t -i concerto_concerto_1 bash -l` and then you can also "login" as the app user via `setuser app bash --login`.

## Debian Package Installation

Note: For those upgrading Concerto from earlier Debian/Ubuntu versions, make sure that your APT source line looks like this: http://dl.concerto-signage.org/packages/ stretch main

* Add Concerto repository using ```curl -k https://get.concerto-signage.org/add_repo.sh | sh```
* Install Concerto via APT ```sudo apt-get install concerto-full```

## Virtual Server Image (VirtualBox, VMWare, et. al.)

The virtual server image contains a full-stack installation of the Concerto webserver with all components pre-configured.

* Download at [https://dl.concerto-signage.org/concerto_server.ova](https://dl.concerto-signage.org/concerto_server.ova)

Concerto 2 is licensed under the Apache License, Version 2.0.
