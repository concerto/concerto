FROM phusion/passenger-ruby25

LABEL Author="team@concerto-signage.org"

ENV HOME /root
CMD ["/sbin/my_init"]

WORKDIR /tmp
RUN add-apt-repository ppa:libreoffice/ppa
RUN apt-get update
RUN apt-get install -y libreoffice imagemagick ruby-rmagick libmagickcore-dev libmagickwand-dev
RUN TZ=America/Anchorage DEBIAN_FRONTEND=noninteractive apt-get install -y sudo tzdata

RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
COPY tools/nginx.docker.conf /etc/nginx/sites-enabled/concerto.conf

RUN mkdir -p /home/app/concerto/log
WORKDIR /home/app/concerto
COPY . /home/app/concerto
#RUN RAILS_ENV=production bundle exec rake assets:precompile
RUN chown -R app:app /home/app/concerto

WORKDIR /tmp
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/home/app/concerto/doc", "/home/app/concerto/log", "/home/app/concerto/tmp", "/home/app/concerto/config"]
