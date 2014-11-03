FROM phusion/passenger-ruby21

MAINTAINER Concerto Authors "team@concerto-signage.org"

ENV HOME /root
CMD ["/sbin/my_init"]

RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default

COPY tools/nginx.docker.conf /etc/nginx/sites-enabled/concerto.conf

RUN mkdir /home/app/concerto

WORKDIR /tmp
RUN add-apt-repository "deb http://us.archive.ubuntu.com/ubuntu/ trusty universe"
RUN apt-get update
RUN apt-get install -yqq libreoffice
COPY Gemfile /tmp/
COPY Gemfile-reporting /tmp/
COPY Gemfile-plugins /tmp/
COPY Gemfile.lock /tmp/
COPY lib/command_check_docker.rb /tmp/lib/command_check.rb
RUN bundle install
COPY . /home/app/concerto
RUN chown -R app:app /home/app/concerto
RUN chmod 700 /home/app/concerto
RUN chmod 600 /home/app/concerto/log

WORKDIR /home/app/concerto
RUN sudo -u app RAILS_ENV=production rake assets:precompile

WORKDIR /tmp
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/home/app/concerto/doc", "/home/app/concerto/log", "/home/app/concerto/tmp", "/home/app/concerto/config"]