# Concerto 2 Digital Signage System

 [![Build Status](https://travis-ci.org/concerto/concerto.png?branch=master)](https://travis-ci.org/concerto/concerto) [![Join the chat at https://gitter.im/concerto/concerto](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/concerto/concerto?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Full Installation Instructions: [https://github.com/concerto/concerto/wiki/Installing-Concerto-2](https://github.com/concerto/concerto/wiki/Installing-Concerto-2)

## What is Concerto?

Concerto is an open source digital signage system. Users submit graphic, textual, and other content, and moderators approve that content for use in a variety of content feeds which are displayed on screens connected to computers displaying the Concerto frontend.

Each screen has a template that has fields designated for content.  The template can also have a background graphic and a CSS stylesheet.  You can easily define your own templates.

A screen can subscribe its fields to feeds (or channels).  Screens can be public or private (requiring a token).

Users can create content (an image, an iframe, video, rss content, etc.) and submit it to various feeds.  The content can be scheduled for a specific date range.  Content submitted to a feed can be ordered on that feed if desired.  The default ordering is by content start date.

Feeds can be hidden or locked.  Feeds belong to groups.  If the user that submitted the content is an administrator or is authorized to moderate content on the feed based on their group membership permissions then the submission is automatically approved.  Otherwise the content submission to the feed is pending a moderator’s approval.

A screen can define the content display rules for each field. This includes whether content should be displayed in order or randomly or based on priority.  It can also designate the animation for transitions when content is swapped out and in.

There are various plugins that extend functionality which can be added as desired.  You can even write your own.

## Dependencies

* Ruby 2.4.6 or 2.5.5, *Ruby 2.6 is not supported*
* Rubygems
* Imagemagick, GhostScript, Poppler-Utils
* LibreOffice
* Webserver (Apache/Unicorn/Thin/Nginx)
* Rack interface to the webserver (Passenger, FastCGI)
* ActiveRecord-compatible database (Mysql, SQLite, Postgres)
* Nodejs as the javascript engine (as of version 2.4.0)

## Docker Image

To build and run the docker image locally, (make sure you don't already have port 80 in use):

```
1. git clone http://github.com/concerto/concerto
2. cd concerto
3. docker build -t concerto .
4. docker-compose up
```

To get into the concerto container: `docker exec -t -i concerto_concerto_1 bash -l` and then you can also "login" as the app user via `setuser app bash --login`.

** Note - we are still working on a viable docker image capable of handling persistence and upgrades. **

## Debian Package Installation

Note: For those upgrading Concerto from earlier Debian/Ubuntu versions, make sure that your APT source line looks like this: http://dl.concerto-signage.org/packages/ stretch main

* Add Concerto repository using ```curl -k https://get.concerto-signage.org/add_repo.sh | sh```
* Install Concerto via APT ```sudo apt-get install concerto-full```

## Virtual Server Image (VirtualBox, VMWare, et. al.)

The virtual server image contains a full-stack installation of the Concerto webserver with all components pre-configured.

* Download at [https://dl.concerto-signage.org/concerto_server.ova](https://dl.concerto-signage.org/concerto_server.ova)

Concerto 2 is licensed under the Apache License, Version 2.0.
