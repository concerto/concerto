# the ruby version is specified in the Dockerfile and the nginx.docker.conf files
FROM phusion/passenger-ruby26:2.3.0

LABEL Author="team@concerto-signage.org"

# because phusion says to...
ENV HOME /root
CMD ["/sbin/my_init"]

# set up for eastern timezone by default
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
&& DEBIAN_FRONTEND=noninteractive install_clean tzdata

# we need libreoffice to convert documents to pdfs, imagemagick for graphics handling, nmap to tell us if the db is up
WORKDIR /tmp
RUN add-apt-repository ppa:libreoffice/ppa \ 
&& install_clean libreoffice ghostscript libgs-dev imagemagick ruby-rmagick libmagickcore-dev libmagickwand-dev nmap gsfonts poppler-utils

# enable nginx and configure the site
RUN rm -f /etc/service/nginx/down \
&& rm /etc/nginx/sites-enabled/default
COPY tools/nginx.docker.conf /etc/nginx/sites-enabled/concerto.conf

# set up the concerto application
RUN mkdir -p /home/app/concerto/log \
&& mkdir -p /home/app/concerto/tmp
WORKDIR /home/app/concerto
COPY . /home/app/concerto
COPY config/database.yml.docker /home/app/concerto/config/database.yml
RUN chown -R app:app /home/app/concerto \
&& setuser app bash --login -c "cd /home/app/concerto && gem install bundler -v '2.3.19' && RAILS_ENV=production bundle install --path=vendor/bundle"

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
RUN sed 's/domain="coder" rights="none" pattern="PDF"/domain="coder" rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml > /tmp/policy.xml \
&& mv /tmp/policy.xml /etc/ImageMagick-6/policy.xml

RUN rm -rf /tmp/* /var/tmp/*

# TODO! we still need to figure out how to handle updates and accommodate changes from optional plugins
# db for schema.rb changes on migrations from plugins
# doc for custom help
# log for logs
# tmp for locks and assets?
# public for assets
# vendor for plugin gems
# what about Gemfile.lock and Gemfile-plugins and Gemfile-plugins.bak?
VOLUME ["/home/app/concerto/db", "/home/app/concerto/doc", "/home/app/concerto/log", "/home/app/concerto/tmp", "/home/app/concerto/public", "/home/app/concerto/vendor"]

