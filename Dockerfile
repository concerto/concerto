# the ruby version is specified in the Dockerfile and the nginx.docker.conf files
FROM phusion/passenger-ruby25

LABEL Author="team@concerto-signage.org"

# because phusion says to...
ENV HOME /root
CMD ["/sbin/my_init"]

# we need libreoffice to convert documents to pdfs, imagemagick for graphics handling, nmap to tell us if the db is up
WORKDIR /tmp
RUN add-apt-repository ppa:libreoffice/ppa
RUN apt-get update
RUN install_clean libreoffice ghostscript libgs-dev imagemagick ruby-rmagick libmagickcore-dev libmagickwand-dev nmap gsfonts poppler-utils

# set up for eastern timezone by default
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN DEBIAN_FRONTEND=noninteractive install_clean tzdata

# enable nginx and configure the site
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
COPY tools/nginx.docker.conf /etc/nginx/sites-enabled/concerto.conf

# set up the concerto application
RUN mkdir -p /home/app/concerto/log
RUN mkdir -p /home/app/concerto/tmp
WORKDIR /home/app/concerto
COPY . /home/app/concerto
COPY config/database.yml.docker /home/app/concerto/config/database.yml
RUN chown -R app:app /home/app/concerto
RUN setuser app bash --login -c "cd /home/app/concerto && gem install bundler -v '1.17.3' && RAILS_ENV=production bundle install --path=vendor/bundle"

# set up the background worker
RUN mkdir -p /etc/service/concerto_clockwork
COPY tools/service.clockwork.docker.sh /etc/service/concerto_clockwork/run
RUN chmod +x /etc/service/concerto_clockwork/run

RUN mkdir -p /etc/service/concerto_worker
COPY tools/service.worker.docker.sh /etc/service/concerto_worker/run
RUN chmod +x /etc/service/concerto_worker/run

# set up migration, and assets to precompile on each startup, but waits for db to be reachable first
RUN mkdir -p /etc/my_init.d
COPY tools/startup.docker.sh /etc/my_init.d/99_startup_concerto.sh
RUN chmod +x /etc/my_init.d/99_startup_concerto.sh

# set up log rotation
COPY tools/logrotate.app.docker /etc/logrotate.d/concerto
RUN chmod 0644 /etc/logrotate.d/concerto

# fix Imagemagick policy for converting files
# https://stackoverflow.com/a/52661288/1778068
RUN cat /etc/ImageMagick-6/policy.xml | sed 's/domain="coder" rights="none" pattern="PDF"/domain="coder" rights="read|write" pattern="PDF"/' >/etc/ImageMagick-6/policy.xml

WORKDIR /tmp
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# concerto will probably fail if any plugins are added/removed/changed because that is in the /home/app/concerto/Gemfile-plugin
# file which doesn't persist
VOLUME ["/home/app/concerto/doc", "/home/app/concerto/log", "/home/app/concerto/tmp", "/home/app/concerto/config"]
