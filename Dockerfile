FROM phusion/passenger-ruby21

MAINTAINER Concerto Authors "team@concerto-signage.org"

ENV HOME /root
CMD ["/sbin/my_init"]

RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default

COPY tools/nginx.docker.conf /etc/nginx/sites-enabled/concerto.conf

RUN mkdir /home/app/concerto

WORKDIR /tmp
COPY Gemfile /tmp/
COPY Gemfile-reporting /tmp/
COPY Gemfile-plugins /tmp/
COPY Gemfile.lock /tmp/
COPY lib/command_check_docker.rb /tmp/lib/command_check.rb
RUN bundle install
COPY . /home/app/concerto

USER app
WORKDIR /home/app/concerto
RUN git submodule update --init --recursive

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER root
