FROM debian

MAINTAINER Concerto Authors "team@concerto-signage.org"

RUN echo "deb http://ftp.us.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list

RUN apt-get update
RUN apt-get install -y build-essential git-core imagemagick nodejs ruby1.9.1-full
RUN apt-get install -y libmysqlclient18 librmagick-ruby libruby1.9.1 libpq5
RUN apt-get install -y zlib1g-dev libmagickcore-dev libmagickwand-dev libsqlite3-dev libmysqlclient-dev libpq-dev libxslt-dev libssl-dev

RUN apt-get install -y libreoffice

RUN gem install bundler

RUN adduser --disabled-password --home=/concerto --gecos "Concerto User" concerto
RUN su concerto -c "git clone https://github.com/concerto/concerto.git /concerto/rails-root"
RUN sh -c "cd /concerto/rails-root/ && bundle install"

RUN apt-get autoremove
RUN apt-get clean

USER concerto
VOLUME ["/concerto/rails-root/doc/coverage"]

ENTRYPOINT ["/bin/sh", "-c", "cd /concerto/rails-root && rake test"]