FROM phusion/passenger-ruby24

LABEL Author="team@concerto-signage.org"

ENV HOME /root
CMD ["/sbin/my_init"]

WORKDIR /tmp
RUN add-apt-repository ppa:libreoffice/ppa
RUN apt-get update
RUN install_clean libreoffice imagemagick ruby-rmagick libmagickcore-dev libmagickwand-dev nmap gsfonts
RUN TZ=America/New_York DEBIAN_FRONTEND=noninteractive install_clean tzdata

RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
COPY tools/nginx.docker.conf /etc/nginx/sites-enabled/concerto.conf

RUN mkdir -p /home/app/concerto/log
RUN mkdir -p /home/app/concerto/tmp
WORKDIR /home/app/concerto
COPY . /home/app/concerto
COPY config/database.yml.docker /home/app/concerto/config/database.yml

RUN chown -R app:app /home/app/concerto
RUN setuser app bash --login -c "cd /home/app/concerto; RAILS_ENV=production bundle install"

RUN mkdir -p /etc/my_init.d
# cannot start app until db exists...
COPY tools/00_precompile.sh /etc/my_init.d/99_precompile.sh
RUN chmod +x /etc/my_init.d/99_precompile.sh

WORKDIR /tmp
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/home/app/concerto/doc", "/home/app/concerto/log", "/home/app/concerto/tmp", "/home/app/concerto/config"]
